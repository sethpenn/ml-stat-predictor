# Data Pipeline & Web Scraping Architecture

## Overview

This document details the data ingestion pipeline responsible for collecting, processing, and storing historical and real-time sports statistics from various web sources.

## Data Sources

### Primary Sources

| Source | URL Pattern | Data Available | Update Frequency |
|--------|-------------|----------------|------------------|
| Pro-Football-Reference | pro-football-reference.com | NFL game logs, player stats, team stats | Daily during season |
| Basketball-Reference | basketball-reference.com | NBA game logs, player stats, box scores | Daily during season |
| Baseball-Reference | baseball-reference.com | MLB game logs, player stats, team stats | Daily during season |
| ESPN | espn.com/nfl, /nba, /mlb | Schedules, scores, rosters, injuries | Real-time |

### Data Categories

```
Historical Data (Backfill):
├── Game Results (10+ years)
│   ├── Final scores
│   ├── Quarter/inning/half scores
│   └── Venue and attendance
├── Player Statistics
│   ├── Per-game stats
│   ├── Season totals
│   └── Career stats
├── Team Statistics
│   ├── Season records
│   ├── Offensive/defensive rankings
│   └── Home/away splits
└── Schedules
    ├── Regular season
    └── Playoffs

Current Season Data:
├── Daily game results
├── Updated player stats
├── Injury reports
├── Roster changes
└── Standings updates
```

## Scraping Architecture

### Technology Stack

- **Scrapy 2.11** - Primary scraping framework for static content
- **Playwright** - JavaScript-rendered content and dynamic pages
- **Rotating Proxies** - IP rotation to avoid blocks
- **User-Agent Rotation** - Mimic different browsers
- **Redis** - Request deduplication and rate limiting

### Spider Design Pattern

```python
# scrapers/spiders/base_spider.py
from scrapy import Spider
from scrapy.http import Request
import logging

class BaseStatsSpider(Spider):
    """Base spider with common functionality for all sports scrapers."""

    # Rate limiting settings
    custom_settings = {
        'DOWNLOAD_DELAY': 2,
        'RANDOMIZE_DOWNLOAD_DELAY': True,
        'CONCURRENT_REQUESTS_PER_DOMAIN': 2,
        'RETRY_TIMES': 3,
        'RETRY_HTTP_CODES': [500, 502, 503, 504, 408, 429],
    }

    def __init__(self, season=None, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.season = season or self.get_current_season()
        self.logger = logging.getLogger(self.name)

    def get_current_season(self):
        """Determine current season based on date."""
        raise NotImplementedError

    def parse_game(self, response):
        """Parse individual game data."""
        raise NotImplementedError

    def parse_player_stats(self, response):
        """Parse player statistics."""
        raise NotImplementedError


# scrapers/spiders/nba_spider.py
class NBASpider(BaseStatsSpider):
    name = 'nba_basketball_reference'
    allowed_domains = ['basketball-reference.com']

    def start_requests(self):
        """Generate requests for each month of the season."""
        base_url = 'https://www.basketball-reference.com/leagues/NBA_{}_games-{}.html'
        months = ['october', 'november', 'december', 'january',
                  'february', 'march', 'april', 'may', 'june']

        for month in months:
            url = base_url.format(self.season, month)
            yield Request(url, callback=self.parse_schedule)

    def parse_schedule(self, response):
        """Parse monthly schedule page."""
        for row in response.css('table#schedule tbody tr'):
            game_url = row.css('td[data-stat="box_score_text"] a::attr(href)').get()
            if game_url:
                yield response.follow(game_url, callback=self.parse_game)

    def parse_game(self, response):
        """Extract box score and game details."""
        game_data = {
            'external_id': response.url.split('/')[-1].replace('.html', ''),
            'date': response.css('div.scorebox_meta div:first-child::text').get(),
            'home_team': self.extract_team_data(response, 'home'),
            'away_team': self.extract_team_data(response, 'away'),
            'player_stats': self.extract_player_stats(response),
        }
        yield game_data
```

### Playwright Integration for Dynamic Content

```python
# scrapers/playwright_scrapers/dynamic_scraper.py
from playwright.async_api import async_playwright
import asyncio

class DynamicContentScraper:
    """Handle JavaScript-rendered content."""

    async def scrape_espn_schedule(self, sport: str, date: str) -> dict:
        """Scrape ESPN schedule that requires JS rendering."""
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            context = await browser.new_context(
                user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            )
            page = await context.new_page()

            url = f'https://www.espn.com/{sport}/schedule/_/date/{date}'
            await page.goto(url, wait_until='networkidle')

            # Wait for schedule table to load
            await page.wait_for_selector('.Schedule__Table')

            games = await page.evaluate('''
                () => {
                    const games = [];
                    document.querySelectorAll('.Schedule__Game').forEach(game => {
                        games.push({
                            homeTeam: game.querySelector('.home-team')?.textContent,
                            awayTeam: game.querySelector('.away-team')?.textContent,
                            time: game.querySelector('.game-time')?.textContent,
                        });
                    });
                    return games;
                }
            ''')

            await browser.close()
            return games
```

## Data Pipeline Architecture

### Apache Airflow DAGs

```python
# dags/daily_stats_ingestion.py
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.sensors.external_task import ExternalTaskSensor
from datetime import datetime, timedelta

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'daily_nba_stats_ingestion',
    default_args=default_args,
    description='Daily NBA stats scraping and processing',
    schedule_interval='0 6 * * *',  # 6 AM daily
    start_date=datetime(2024, 10, 1),
    catchup=False,
    tags=['nba', 'scraping', 'daily'],
) as dag:

    # Task 1: Run Scrapy spider
    scrape_games = BashOperator(
        task_id='scrape_nba_games',
        bash_command='''
            cd /opt/scrapers && \
            scrapy crawl nba_basketball_reference \
                -a date={{ ds }} \
                -o /tmp/nba_games_{{ ds }}.json
        ''',
    )

    # Task 2: Validate scraped data
    validate_data = PythonOperator(
        task_id='validate_scraped_data',
        python_callable=validate_game_data,
        op_kwargs={'file_path': '/tmp/nba_games_{{ ds }}.json'},
    )

    # Task 3: Transform and normalize
    transform_data = PythonOperator(
        task_id='transform_game_data',
        python_callable=transform_and_normalize,
        op_kwargs={'file_path': '/tmp/nba_games_{{ ds }}.json'},
    )

    # Task 4: Load into database
    load_to_db = PythonOperator(
        task_id='load_to_postgres',
        python_callable=load_games_to_db,
        op_kwargs={'file_path': '/tmp/nba_games_{{ ds }}_transformed.json'},
    )

    # Task 5: Update aggregations
    update_aggregations = PythonOperator(
        task_id='update_stat_aggregations',
        python_callable=refresh_materialized_views,
    )

    # Task 6: Clear relevant caches
    clear_cache = PythonOperator(
        task_id='clear_redis_cache',
        python_callable=invalidate_cache_keys,
        op_kwargs={'patterns': ['games:list:nba:*', 'teams:standings:nba:*']},
    )

    # Define task dependencies
    scrape_games >> validate_data >> transform_data >> load_to_db >> update_aggregations >> clear_cache
```

### Historical Backfill DAG

```python
# dags/historical_backfill.py
with DAG(
    'historical_nba_backfill',
    default_args=default_args,
    description='Backfill historical NBA data',
    schedule_interval=None,  # Triggered manually
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['nba', 'backfill', 'historical'],
) as dag:

    # Generate tasks for each season (2014-2024)
    seasons = range(2014, 2025)

    previous_task = None
    for season in seasons:
        scrape_season = BashOperator(
            task_id=f'scrape_season_{season}',
            bash_command=f'''
                cd /opt/scrapers && \
                scrapy crawl nba_basketball_reference \
                    -a season={season} \
                    -o /tmp/nba_season_{season}.json
            ''',
        )

        process_season = PythonOperator(
            task_id=f'process_season_{season}',
            python_callable=process_historical_season,
            op_kwargs={'season': season},
        )

        scrape_season >> process_season

        if previous_task:
            previous_task >> scrape_season
        previous_task = process_season
```

## Data Transformation Pipeline

### Normalization Layer

```python
# transformers/normalize_stats.py
from typing import Dict, Any
from datetime import datetime

class StatsNormalizer:
    """Normalize raw scraped data into consistent schema."""

    # Sport-specific stat mappings
    NBA_STAT_MAPPING = {
        'pts': 'points',
        'reb': 'rebounds',
        'ast': 'assists',
        'stl': 'steals',
        'blk': 'blocks',
        'tov': 'turnovers',
        'fg': 'field_goals_made',
        'fga': 'field_goals_attempted',
        '3p': 'three_pointers_made',
        '3pa': 'three_pointers_attempted',
        'ft': 'free_throws_made',
        'fta': 'free_throws_attempted',
        'min': 'minutes_played',
        '+/-': 'plus_minus',
    }

    NFL_STAT_MAPPING = {
        'pass_yds': 'passing_yards',
        'pass_td': 'passing_touchdowns',
        'rush_yds': 'rushing_yards',
        'rush_td': 'rushing_touchdowns',
        'rec': 'receptions',
        'rec_yds': 'receiving_yards',
        'rec_td': 'receiving_touchdowns',
        'int': 'interceptions',
        'fum': 'fumbles',
    }

    def normalize_game(self, raw_data: Dict[str, Any], sport: str) -> Dict[str, Any]:
        """Normalize raw game data to standard schema."""
        return {
            'external_id': raw_data['external_id'],
            'sport': sport,
            'game_date': self.parse_date(raw_data['date']),
            'home_team': self.normalize_team(raw_data['home_team']),
            'away_team': self.normalize_team(raw_data['away_team']),
            'home_score': int(raw_data['home_score']),
            'away_score': int(raw_data['away_score']),
            'status': 'final',
            'player_stats': [
                self.normalize_player_stats(p, sport)
                for p in raw_data.get('player_stats', [])
            ],
        }

    def normalize_player_stats(self, raw_stats: Dict, sport: str) -> Dict:
        """Normalize player statistics using sport-specific mapping."""
        mapping = self.NBA_STAT_MAPPING if sport == 'NBA' else self.NFL_STAT_MAPPING

        normalized = {
            'player_external_id': raw_stats['player_id'],
            'player_name': raw_stats['name'],
            'team': raw_stats['team'],
            'stats': {},
        }

        for raw_key, value in raw_stats.items():
            if raw_key in mapping:
                normalized['stats'][mapping[raw_key]] = self.parse_stat_value(value)

        return normalized

    @staticmethod
    def parse_stat_value(value: Any) -> float:
        """Parse stat value to float, handling edge cases."""
        if value is None or value == '' or value == '-':
            return 0.0
        try:
            return float(value)
        except ValueError:
            return 0.0
```

### Data Quality Validation

```python
# quality/schema_validation.py
from pydantic import BaseModel, validator, Field
from typing import List, Optional
from datetime import datetime

class PlayerStatSchema(BaseModel):
    """Validate player stat records."""
    player_external_id: str
    player_name: str
    team: str
    stats: dict

    @validator('stats')
    def validate_stats(cls, v):
        """Ensure all stat values are non-negative."""
        for key, value in v.items():
            if isinstance(value, (int, float)) and value < 0:
                if key != 'plus_minus':  # plus_minus can be negative
                    raise ValueError(f'Stat {key} cannot be negative: {value}')
        return v

class GameSchema(BaseModel):
    """Validate game records."""
    external_id: str
    sport: str = Field(..., regex='^(NBA|NFL|MLB)$')
    game_date: datetime
    home_team: str
    away_team: str
    home_score: int = Field(..., ge=0)
    away_score: int = Field(..., ge=0)
    status: str
    player_stats: List[PlayerStatSchema]

    @validator('game_date')
    def validate_date(cls, v):
        """Ensure game date is not in the future."""
        if v > datetime.now():
            raise ValueError('Game date cannot be in the future')
        return v

class DataQualityChecker:
    """Run data quality checks on scraped data."""

    def check_completeness(self, games: List[dict]) -> dict:
        """Check for missing required fields."""
        issues = []
        for game in games:
            if not game.get('player_stats'):
                issues.append(f"Game {game['external_id']}: No player stats")
            if len(game.get('player_stats', [])) < 10:
                issues.append(f"Game {game['external_id']}: Too few players")

        return {
            'passed': len(issues) == 0,
            'issues': issues,
        }

    def check_consistency(self, games: List[dict]) -> dict:
        """Check for data consistency issues."""
        issues = []
        for game in games:
            # Verify scores match player totals
            home_player_points = sum(
                p['stats'].get('points', 0)
                for p in game['player_stats']
                if p['team'] == game['home_team']
            )
            if abs(home_player_points - game['home_score']) > 5:
                issues.append(
                    f"Game {game['external_id']}: Score mismatch "
                    f"(team: {game['home_score']}, players: {home_player_points})"
                )

        return {
            'passed': len(issues) == 0,
            'issues': issues,
        }
```

## Anti-Blocking Strategies

### Proxy Rotation

```python
# scrapers/middleware/proxy_middleware.py
import random
from scrapy import signals

class RotatingProxyMiddleware:
    """Rotate proxies for each request."""

    def __init__(self, proxy_list):
        self.proxies = proxy_list
        self.current_proxy = None

    @classmethod
    def from_crawler(cls, crawler):
        proxy_list = crawler.settings.getlist('PROXY_LIST')
        middleware = cls(proxy_list)
        crawler.signals.connect(middleware.spider_opened, signal=signals.spider_opened)
        return middleware

    def process_request(self, request, spider):
        self.current_proxy = random.choice(self.proxies)
        request.meta['proxy'] = self.current_proxy
        spider.logger.debug(f'Using proxy: {self.current_proxy}')

    def process_exception(self, request, exception, spider):
        # Remove failed proxy from list
        if self.current_proxy in self.proxies:
            self.proxies.remove(self.current_proxy)
            spider.logger.warning(f'Removed failed proxy: {self.current_proxy}')
```

### Rate Limiting

```python
# scrapers/middleware/rate_limit.py
import time
from collections import defaultdict

class AdaptiveRateLimitMiddleware:
    """Adaptive rate limiting based on response codes."""

    def __init__(self):
        self.domain_delays = defaultdict(lambda: 2.0)  # Default 2s delay
        self.last_request_time = defaultdict(float)

    def process_request(self, request, spider):
        domain = request.url.split('/')[2]

        # Enforce minimum delay
        elapsed = time.time() - self.last_request_time[domain]
        if elapsed < self.domain_delays[domain]:
            time.sleep(self.domain_delays[domain] - elapsed)

        self.last_request_time[domain] = time.time()

    def process_response(self, request, response, spider):
        domain = request.url.split('/')[2]

        # Increase delay if we're getting rate limited
        if response.status == 429:
            self.domain_delays[domain] *= 2
            spider.logger.warning(f'Rate limited, increasing delay for {domain}')
        elif response.status == 200:
            # Slowly decrease delay on success
            self.domain_delays[domain] = max(1.0, self.domain_delays[domain] * 0.95)

        return response
```

## Monitoring & Alerting

### Scraper Metrics

```python
# scrapers/monitoring/metrics.py
from prometheus_client import Counter, Histogram, Gauge

# Metrics definitions
PAGES_SCRAPED = Counter(
    'scraper_pages_total',
    'Total pages scraped',
    ['spider', 'status']
)

SCRAPE_DURATION = Histogram(
    'scraper_page_duration_seconds',
    'Time to scrape a page',
    ['spider']
)

ITEMS_SCRAPED = Counter(
    'scraper_items_total',
    'Total items extracted',
    ['spider', 'item_type']
)

SCRAPER_ERRORS = Counter(
    'scraper_errors_total',
    'Total scraping errors',
    ['spider', 'error_type']
)

PROXY_HEALTH = Gauge(
    'scraper_proxy_health',
    'Number of healthy proxies',
)
```

### Alerting Rules

```yaml
# monitoring/alerts/scraper_alerts.yml
groups:
  - name: scraper_alerts
    rules:
      - alert: ScraperHighErrorRate
        expr: rate(scraper_errors_total[5m]) > 0.1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High scraper error rate"
          description: "Spider {{ $labels.spider }} has error rate > 10%"

      - alert: ScraperNoData
        expr: increase(scraper_items_total[1h]) == 0
        for: 2h
        labels:
          severity: critical
        annotations:
          summary: "No data scraped"
          description: "No items scraped in the last 2 hours"

      - alert: ProxyPoolLow
        expr: scraper_proxy_health < 5
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Low proxy pool"
          description: "Only {{ $value }} healthy proxies remaining"
```

## Data Retention Policy

| Data Type | Retention | Storage |
|-----------|-----------|---------|
| Raw scraped JSON | 30 days | S3 |
| Game records | Indefinite | PostgreSQL |
| Player stats | Indefinite | TimescaleDB |
| Aggregated stats | Indefinite | PostgreSQL |
| Scraper logs | 90 days | ElasticSearch |
| Pipeline metrics | 1 year | Prometheus |
