# Airflow DAGs

This directory contains all Airflow DAGs for the ML Sport Stat Predictor project.

## Available DAGs

### 1. example_dag.py
A simple example DAG to verify Airflow setup. This DAG:
- Runs basic Python and Bash tasks
- Can be manually triggered for testing
- Verifies that Airflow is working correctly

**Schedule:** Manual trigger only
**Tags:** `example`, `test`

### 2. sports_data_scraper_dag.py
Daily scraping of sports data from multiple sources (NFL, NBA, MLB). This DAG:
- Scrapes game data from multiple sports in parallel
- Validates scraped data quality
- Loads validated data into the database

**Schedule:** Daily at 6 AM UTC
**Tags:** `scraper`, `sports`, `data-pipeline`

**TODO:** Implement actual scraper modules in `/data_pipeline/scrapers/`

### 3. ml_training_dag.py
Weekly training and evaluation of ML prediction models. This DAG:
- Prepares training data with feature engineering
- Trains models for NFL, NBA, and MLB in parallel
- Evaluates model performance
- Registers models in MLflow
- Deploys models to production if they meet criteria

**Schedule:** Weekly on Sunday at 2 AM UTC
**Tags:** `ml`, `training`, `models`

**TODO:** Implement actual ML training modules in `/ml/`

## DAG Development Guidelines

### Best Practices
1. **Idempotency:** All tasks should be idempotent (safe to re-run)
2. **Error Handling:** Use proper try/except blocks and Airflow retries
3. **Logging:** Log important information for debugging
4. **Testing:** Test DAGs locally before deploying
5. **Documentation:** Document complex logic and dependencies

### Task Dependencies
Use the `>>` operator to define task dependencies:
```python
task1 >> task2  # task2 runs after task1
[task1, task2] >> task3  # task3 runs after both task1 and task2
```

### Scheduling
- Use cron expressions for `schedule_interval`
- Set `catchup=False` to prevent backfilling old runs
- Use `max_active_runs=1` to prevent concurrent runs

### Configuration
- Store sensitive data in Airflow Connections or Variables
- Use environment variables for configuration
- Never hardcode credentials in DAG files

## Testing DAGs

### Local Testing
```bash
# Test DAG file for errors
python data_pipeline/dags/your_dag.py

# List all tasks in a DAG
docker exec mlsp-airflow-scheduler airflow tasks list example_dag

# Test a specific task
docker exec mlsp-airflow-scheduler airflow tasks test example_dag print_hello 2024-01-01
```

### Airflow UI
1. Navigate to http://localhost:8080
2. Login with admin credentials
3. Enable the DAG
4. Trigger a manual run
5. Monitor task execution and logs

## Creating New DAGs

1. Create a new Python file in this directory
2. Import required operators and libraries
3. Define default arguments
4. Create the DAG using context manager
5. Define tasks and their dependencies
6. Test the DAG locally
7. Commit and deploy

Example template:
```python
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator

default_args = {
    'owner': 'mlsp',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'my_new_dag',
    default_args=default_args,
    description='Description of my DAG',
    schedule_interval='@daily',
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['category'],
) as dag:

    def my_function():
        print("Hello from my DAG!")

    task = PythonOperator(
        task_id='my_task',
        python_callable=my_function,
    )
```

## Troubleshooting

### DAG not appearing in UI
- Check for Python syntax errors
- Verify file is in the `/data_pipeline/dags/` directory
- Check Airflow logs: `docker logs mlsp-airflow-scheduler`
- Refresh DAGs in UI (may take up to 30 seconds)

### Task failures
- Check task logs in Airflow UI
- Verify database connections
- Check environment variables
- Review retry configuration

### Connection issues
- Verify Airflow connections are configured
- Test database connectivity from worker container
- Check network configuration in docker-compose.yml

## Resources
- [Airflow Documentation](https://airflow.apache.org/docs/)
- [Airflow Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)
- [Project Documentation](/docs/)
