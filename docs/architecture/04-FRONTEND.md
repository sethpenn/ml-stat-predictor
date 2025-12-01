# Frontend Application Specification

## Overview

A modern React-based single-page application for viewing sports predictions, game analysis, and player statistics. The application emphasizes performance, accessibility, and a clean user experience.

## Technology Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| React | 18.x | UI framework |
| TypeScript | 5.x | Type safety |
| Vite | 5.x | Build tool |
| TailwindCSS | 3.x | Styling |
| TanStack Query | 5.x | Server state management |
| Zustand | 4.x | Client state management |
| React Router | 6.x | Routing |
| Recharts | 2.x | Data visualization |
| Axios | 1.x | HTTP client |
| date-fns | 3.x | Date utilities |

## Application Structure

```
frontend/
├── public/
│   ├── favicon.ico
│   └── assets/
│       └── team-logos/
├── src/
│   ├── main.tsx                 # Application entry
│   ├── App.tsx                  # Root component
│   ├── routes.tsx               # Route definitions
│   │
│   ├── components/              # Shared components
│   │   ├── common/
│   │   │   ├── Button/
│   │   │   ├── Card/
│   │   │   ├── Input/
│   │   │   ├── Modal/
│   │   │   ├── Spinner/
│   │   │   ├── Table/
│   │   │   └── Tooltip/
│   │   ├── charts/
│   │   │   ├── LineChart/
│   │   │   ├── BarChart/
│   │   │   ├── GaugeChart/
│   │   │   └── SparkLine/
│   │   └── layout/
│   │       ├── Header/
│   │       ├── Sidebar/
│   │       ├── Footer/
│   │       └── PageLayout/
│   │
│   ├── features/                # Feature modules
│   │   ├── dashboard/
│   │   │   ├── Dashboard.tsx
│   │   │   ├── DashboardStats.tsx
│   │   │   ├── UpcomingGames.tsx
│   │   │   └── TopPredictions.tsx
│   │   ├── games/
│   │   │   ├── GamesList.tsx
│   │   │   ├── GameCard.tsx
│   │   │   ├── GameDetail.tsx
│   │   │   ├── GamePrediction.tsx
│   │   │   └── LiveScores.tsx
│   │   ├── players/
│   │   │   ├── PlayersList.tsx
│   │   │   ├── PlayerCard.tsx
│   │   │   ├── PlayerDetail.tsx
│   │   │   ├── PlayerStats.tsx
│   │   │   └── PlayerPrediction.tsx
│   │   ├── teams/
│   │   │   ├── TeamsList.tsx
│   │   │   ├── TeamCard.tsx
│   │   │   ├── TeamDetail.tsx
│   │   │   └── TeamStats.tsx
│   │   └── predictions/
│   │       ├── PredictionsList.tsx
│   │       ├── PredictionCard.tsx
│   │       ├── PredictionHistory.tsx
│   │       └── AccuracyTracker.tsx
│   │
│   ├── hooks/                   # Custom hooks
│   │   ├── useDebounce.ts
│   │   ├── useLocalStorage.ts
│   │   ├── useMediaQuery.ts
│   │   └── usePagination.ts
│   │
│   ├── services/                # API services
│   │   ├── api.ts               # Axios instance
│   │   ├── gamesService.ts
│   │   ├── playersService.ts
│   │   ├── teamsService.ts
│   │   └── predictionsService.ts
│   │
│   ├── stores/                  # Zustand stores
│   │   ├── useAuthStore.ts
│   │   ├── useFilterStore.ts
│   │   └── usePreferencesStore.ts
│   │
│   ├── types/                   # TypeScript types
│   │   ├── api.ts
│   │   ├── game.ts
│   │   ├── player.ts
│   │   ├── team.ts
│   │   └── prediction.ts
│   │
│   ├── utils/                   # Utilities
│   │   ├── formatters.ts
│   │   ├── validators.ts
│   │   └── constants.ts
│   │
│   └── styles/
│       └── globals.css
│
├── tests/
│   ├── components/
│   ├── features/
│   └── utils/
│
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.js
└── postcss.config.js
```

## Core Features

### 1. Dashboard

The main landing page providing an overview of today's predictions and recent performance.

```tsx
// features/dashboard/Dashboard.tsx
import { useQuery } from '@tanstack/react-query';
import { DashboardStats } from './DashboardStats';
import { UpcomingGames } from './UpcomingGames';
import { TopPredictions } from './TopPredictions';
import { RecentResults } from './RecentResults';

export function Dashboard() {
  const { data: stats } = useQuery({
    queryKey: ['dashboard', 'stats'],
    queryFn: () => dashboardService.getStats(),
  });

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Dashboard</h1>

      {/* Quick Stats */}
      <DashboardStats stats={stats} />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Today's Games with Predictions */}
        <UpcomingGames />

        {/* High Confidence Predictions */}
        <TopPredictions />
      </div>

      {/* Recent Prediction Results */}
      <RecentResults />
    </div>
  );
}
```

### 2. Games View

Browse and filter games with prediction details.

```tsx
// features/games/GamesList.tsx
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useFilterStore } from '@/stores/useFilterStore';
import { GameCard } from './GameCard';
import { DatePicker } from '@/components/common/DatePicker';
import { SportFilter } from '@/components/common/SportFilter';

export function GamesList() {
  const { sport, date, setDate, setSport } = useFilterStore();

  const { data: games, isLoading } = useQuery({
    queryKey: ['games', sport, date],
    queryFn: () => gamesService.getGames({ sport, date }),
  });

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex gap-4 items-center">
        <SportFilter value={sport} onChange={setSport} />
        <DatePicker value={date} onChange={setDate} />
      </div>

      {/* Games Grid */}
      {isLoading ? (
        <LoadingSkeleton />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {games?.map((game) => (
            <GameCard key={game.id} game={game} />
          ))}
        </div>
      )}
    </div>
  );
}
```

### 3. Game Detail with Prediction

```tsx
// features/games/GameDetail.tsx
import { useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { PredictionGauge } from '@/components/charts/PredictionGauge';
import { TeamComparison } from './TeamComparison';
import { PlayerMatchups } from './PlayerMatchups';

export function GameDetail() {
  const { gameId } = useParams();

  const { data: game } = useQuery({
    queryKey: ['games', gameId],
    queryFn: () => gamesService.getGame(gameId!),
  });

  const { data: prediction } = useQuery({
    queryKey: ['predictions', 'game', gameId],
    queryFn: () => predictionsService.getGamePrediction(gameId!),
  });

  if (!game || !prediction) return <LoadingSkeleton />;

  return (
    <div className="space-y-6">
      {/* Game Header */}
      <GameHeader game={game} />

      {/* Main Prediction Display */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle>Win Probability</CardTitle>
            </CardHeader>
            <CardContent>
              <PredictionGauge
                homeTeam={game.homeTeam}
                awayTeam={game.awayTeam}
                homeWinProb={prediction.winProbability.home}
              />
              <div className="mt-4 text-center">
                <span className="text-sm text-gray-500">
                  Predicted Spread: {prediction.pointSpread > 0 ? '+' : ''}
                  {prediction.pointSpread}
                </span>
              </div>
            </CardContent>
          </Card>
        </div>

        <div>
          <PredictionConfidence confidence={prediction.confidence} />
        </div>
      </div>

      {/* Team Comparison */}
      <TeamComparison
        homeTeam={game.homeTeam}
        awayTeam={game.awayTeam}
      />

      {/* Key Player Matchups */}
      <PlayerMatchups gameId={game.id} />
    </div>
  );
}
```

### 4. Player Statistics & Predictions

```tsx
// features/players/PlayerDetail.tsx
export function PlayerDetail() {
  const { playerId } = useParams();

  const { data: player } = useQuery({
    queryKey: ['players', playerId],
    queryFn: () => playersService.getPlayer(playerId!),
  });

  const { data: stats } = useQuery({
    queryKey: ['players', playerId, 'stats'],
    queryFn: () => playersService.getPlayerStats(playerId!),
  });

  const { data: upcomingPrediction } = useQuery({
    queryKey: ['predictions', 'player', playerId, 'upcoming'],
    queryFn: () => predictionsService.getPlayerPrediction(playerId!),
  });

  return (
    <div className="space-y-6">
      {/* Player Header */}
      <PlayerHeader player={player} />

      {/* Upcoming Game Prediction */}
      {upcomingPrediction && (
        <Card>
          <CardHeader>
            <CardTitle>Next Game Prediction</CardTitle>
            <CardDescription>vs {upcomingPrediction.opponent}</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-3 gap-4">
              {Object.entries(upcomingPrediction.stats).map(([stat, pred]) => (
                <StatPredictionCard
                  key={stat}
                  statName={stat}
                  prediction={pred}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Historical Performance */}
      <Card>
        <CardHeader>
          <CardTitle>Season Statistics</CardTitle>
        </CardHeader>
        <CardContent>
          <StatsTable stats={stats} />
          <div className="mt-6">
            <PerformanceChart data={stats.gameLog} />
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
```

## State Management

### Server State (TanStack Query)

```tsx
// services/api.ts
import axios from 'axios';
import { QueryClient } from '@tanstack/react-query';

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  timeout: 10000,
});

// Request interceptor for auth
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      retry: 2,
      refetchOnWindowFocus: false,
    },
  },
});
```

### Client State (Zustand)

```tsx
// stores/useFilterStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface FilterState {
  sport: 'NFL' | 'NBA' | 'MLB' | 'all';
  date: Date;
  setSport: (sport: FilterState['sport']) => void;
  setDate: (date: Date) => void;
}

export const useFilterStore = create<FilterState>()(
  persist(
    (set) => ({
      sport: 'all',
      date: new Date(),
      setSport: (sport) => set({ sport }),
      setDate: (date) => set({ date }),
    }),
    {
      name: 'filter-storage',
    }
  )
);

// stores/usePreferencesStore.ts
interface PreferencesState {
  theme: 'light' | 'dark' | 'system';
  favoriteSports: string[];
  favoriteTeams: number[];
  setTheme: (theme: PreferencesState['theme']) => void;
  toggleFavoriteSport: (sport: string) => void;
  toggleFavoriteTeam: (teamId: number) => void;
}

export const usePreferencesStore = create<PreferencesState>()(
  persist(
    (set) => ({
      theme: 'system',
      favoriteSports: [],
      favoriteTeams: [],
      setTheme: (theme) => set({ theme }),
      toggleFavoriteSport: (sport) =>
        set((state) => ({
          favoriteSports: state.favoriteSports.includes(sport)
            ? state.favoriteSports.filter((s) => s !== sport)
            : [...state.favoriteSports, sport],
        })),
      toggleFavoriteTeam: (teamId) =>
        set((state) => ({
          favoriteTeams: state.favoriteTeams.includes(teamId)
            ? state.favoriteTeams.filter((id) => id !== teamId)
            : [...state.favoriteTeams, teamId],
        })),
    }),
    {
      name: 'preferences-storage',
    }
  )
);
```

## TypeScript Types

```tsx
// types/game.ts
export interface Team {
  id: number;
  name: string;
  city: string;
  abbreviation: string;
  conference: string;
  division: string;
  logoUrl: string;
}

export interface Game {
  id: number;
  sport: 'NFL' | 'NBA' | 'MLB';
  homeTeam: Team;
  awayTeam: Team;
  gameDate: string;
  venue: string;
  homeScore: number | null;
  awayScore: number | null;
  status: 'scheduled' | 'in_progress' | 'final';
}

// types/prediction.ts
export interface GamePrediction {
  gameId: number;
  winProbability: {
    home: number;
    away: number;
  };
  pointSpread: number;
  totalPoints: number;
  confidence: number;
  modelVersion: string;
  createdAt: string;
}

export interface PlayerPrediction {
  playerId: number;
  gameId: number;
  opponent: string;
  stats: {
    [key: string]: {
      predicted: number;
      confidenceInterval: [number, number];
    };
  };
}

// types/player.ts
export interface Player {
  id: number;
  firstName: string;
  lastName: string;
  team: Team;
  position: string;
  jerseyNumber: number;
  heightInches: number;
  weightLbs: number;
  isActive: boolean;
}

export interface PlayerGameStats {
  gameId: number;
  date: string;
  opponent: Team;
  minutes: number;
  stats: Record<string, number>;
}
```

## Routing

```tsx
// routes.tsx
import { createBrowserRouter } from 'react-router-dom';
import { PageLayout } from '@/components/layout/PageLayout';

export const router = createBrowserRouter([
  {
    element: <PageLayout />,
    children: [
      {
        path: '/',
        element: <Dashboard />,
      },
      {
        path: '/games',
        element: <GamesList />,
      },
      {
        path: '/games/:gameId',
        element: <GameDetail />,
      },
      {
        path: '/players',
        element: <PlayersList />,
      },
      {
        path: '/players/:playerId',
        element: <PlayerDetail />,
      },
      {
        path: '/teams',
        element: <TeamsList />,
      },
      {
        path: '/teams/:teamId',
        element: <TeamDetail />,
      },
      {
        path: '/predictions',
        element: <PredictionsHistory />,
      },
      {
        path: '/predictions/accuracy',
        element: <AccuracyTracker />,
      },
    ],
  },
]);
```

## Key Components

### Prediction Gauge

```tsx
// components/charts/PredictionGauge.tsx
import { useMemo } from 'react';

interface Props {
  homeTeam: Team;
  awayTeam: Team;
  homeWinProb: number;
}

export function PredictionGauge({ homeTeam, awayTeam, homeWinProb }: Props) {
  const awayWinProb = 1 - homeWinProb;

  const winner = homeWinProb > 0.5 ? homeTeam : awayTeam;
  const winnerProb = Math.max(homeWinProb, awayWinProb);

  return (
    <div className="space-y-4">
      {/* Visual gauge bar */}
      <div className="relative h-12 bg-gray-200 rounded-full overflow-hidden">
        <div
          className="absolute left-0 top-0 h-full bg-blue-500 transition-all"
          style={{ width: `${homeWinProb * 100}%` }}
        />
        <div
          className="absolute right-0 top-0 h-full bg-red-500 transition-all"
          style={{ width: `${awayWinProb * 100}%` }}
        />
      </div>

      {/* Team labels */}
      <div className="flex justify-between">
        <div className="text-center">
          <img
            src={homeTeam.logoUrl}
            alt={homeTeam.name}
            className="w-12 h-12 mx-auto"
          />
          <p className="font-semibold">{homeTeam.abbreviation}</p>
          <p className="text-2xl font-bold text-blue-600">
            {(homeWinProb * 100).toFixed(0)}%
          </p>
        </div>

        <div className="text-center self-center">
          <span className="text-gray-400">vs</span>
        </div>

        <div className="text-center">
          <img
            src={awayTeam.logoUrl}
            alt={awayTeam.name}
            className="w-12 h-12 mx-auto"
          />
          <p className="font-semibold">{awayTeam.abbreviation}</p>
          <p className="text-2xl font-bold text-red-600">
            {(awayWinProb * 100).toFixed(0)}%
          </p>
        </div>
      </div>
    </div>
  );
}
```

### Game Card

```tsx
// features/games/GameCard.tsx
import { Link } from 'react-router-dom';
import { format } from 'date-fns';

interface Props {
  game: Game;
}

export function GameCard({ game }: Props) {
  const prediction = usePrediction(game.id);

  return (
    <Link to={`/games/${game.id}`}>
      <Card className="hover:shadow-lg transition-shadow">
        <CardContent className="p-4">
          {/* Game Time */}
          <div className="text-sm text-gray-500 mb-2">
            {format(new Date(game.gameDate), 'MMM d, h:mm a')}
          </div>

          {/* Teams */}
          <div className="flex justify-between items-center">
            <TeamDisplay team={game.awayTeam} score={game.awayScore} />
            <span className="text-gray-400">@</span>
            <TeamDisplay team={game.homeTeam} score={game.homeScore} />
          </div>

          {/* Prediction Summary */}
          {prediction && (
            <div className="mt-4 pt-4 border-t">
              <div className="flex justify-between text-sm">
                <span>Predicted Winner:</span>
                <span className="font-semibold">
                  {prediction.winProbability.home > 0.5
                    ? game.homeTeam.abbreviation
                    : game.awayTeam.abbreviation}
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span>Spread:</span>
                <span>
                  {prediction.pointSpread > 0 ? '+' : ''}
                  {prediction.pointSpread.toFixed(1)}
                </span>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </Link>
  );
}
```

## Responsive Design

```css
/* Tailwind breakpoints used */
/* sm: 640px, md: 768px, lg: 1024px, xl: 1280px, 2xl: 1536px */

/* Example responsive classes */
.grid-responsive {
  @apply grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4;
}

.sidebar-responsive {
  @apply fixed lg:static inset-y-0 left-0 z-50 w-64 transform -translate-x-full lg:translate-x-0 transition-transform;
}
```

## Testing Strategy

```tsx
// tests/features/GameCard.test.tsx
import { render, screen } from '@testing-library/react';
import { GameCard } from '@/features/games/GameCard';
import { mockGame } from '../mocks/game';

describe('GameCard', () => {
  it('renders team names', () => {
    render(<GameCard game={mockGame} />);

    expect(screen.getByText(mockGame.homeTeam.abbreviation)).toBeInTheDocument();
    expect(screen.getByText(mockGame.awayTeam.abbreviation)).toBeInTheDocument();
  });

  it('shows prediction when available', () => {
    render(<GameCard game={mockGame} />);

    expect(screen.getByText('Predicted Winner:')).toBeInTheDocument();
  });

  it('links to game detail page', () => {
    render(<GameCard game={mockGame} />);

    const link = screen.getByRole('link');
    expect(link).toHaveAttribute('href', `/games/${mockGame.id}`);
  });
});
```

## Performance Optimizations

1. **Code Splitting** - Route-based lazy loading
2. **Image Optimization** - Team logos served via CDN with proper sizing
3. **Query Caching** - TanStack Query with appropriate stale times
4. **Virtualization** - React-window for long lists
5. **Memoization** - React.memo for expensive components
6. **Bundle Analysis** - Vite bundle analyzer integration
