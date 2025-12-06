"""
ML Model Training DAG Template.

This DAG orchestrates the training of machine learning models for sports predictions.
It demonstrates the pattern for periodic model training and evaluation workflows.
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator


def prepare_training_data(**context):
    """
    Prepare and preprocess data for model training.

    This includes:
    - Feature engineering
    - Data cleaning
    - Train/test split
    - Data normalization
    """
    print("Preparing training data...")
    execution_date = context['ds']
    print(f"Execution date: {execution_date}")

    # TODO: Implement data preparation logic
    # Example:
    # from ml.data_preparation import prepare_features
    # train_data, test_data = prepare_features(date=execution_date)
    # return {"train_size": len(train_data), "test_size": len(test_data)}

    print("Training data preparation completed (placeholder)")
    return {"status": "success", "train_size": 1000, "test_size": 200}


def train_nfl_model(**context):
    """Train NFL game outcome prediction model."""
    print("Training NFL prediction model...")

    # TODO: Implement model training logic
    # Example:
    # from ml.models.nfl import NFLPredictor
    # model = NFLPredictor()
    # metrics = model.train(train_data)
    # model.save(f"nfl_model_{execution_date}")
    # return metrics

    print("NFL model training completed (placeholder)")
    return {"accuracy": 0.75, "f1_score": 0.72}


def train_nba_model(**context):
    """Train NBA game outcome prediction model."""
    print("Training NBA prediction model...")

    # TODO: Implement model training logic
    print("NBA model training completed (placeholder)")
    return {"accuracy": 0.78, "f1_score": 0.76}


def train_mlb_model(**context):
    """Train MLB game outcome prediction model."""
    print("Training MLB prediction model...")

    # TODO: Implement model training logic
    print("MLB model training completed (placeholder)")
    return {"accuracy": 0.71, "f1_score": 0.69}


def evaluate_models(**context):
    """
    Evaluate trained models on test data.

    This includes:
    - Performance metrics calculation
    - Model comparison with previous versions
    - Statistical significance tests
    """
    print("Evaluating trained models...")

    # TODO: Implement evaluation logic
    # - Calculate metrics (accuracy, precision, recall, F1)
    # - Compare with baseline and previous models
    # - Generate evaluation reports

    print("Model evaluation completed (placeholder)")
    return {"status": "evaluated"}


def register_models_mlflow(**context):
    """
    Register trained models in MLflow.

    This function logs models, parameters, and metrics to MLflow tracking server.
    """
    print("Registering models in MLflow...")

    # TODO: Implement MLflow registration
    # Example:
    # import mlflow
    # mlflow.set_tracking_uri("http://mlflow:5000")
    # with mlflow.start_run():
    #     mlflow.log_params(params)
    #     mlflow.log_metrics(metrics)
    #     mlflow.sklearn.log_model(model, "model")

    print("Models registered in MLflow (placeholder)")
    return {"status": "registered"}


def deploy_models(**context):
    """
    Deploy models to production if they meet performance criteria.

    This would typically:
    - Compare new model performance with current production model
    - Run A/B testing if needed
    - Deploy to serving infrastructure
    """
    print("Deploying models...")

    # TODO: Implement deployment logic
    # - Check if new model beats production model
    # - If yes, deploy to production
    # - Update model version in database

    print("Model deployment completed (placeholder)")
    return {"status": "deployed"}


# Default arguments
default_args = {
    'owner': 'mlsp',
    'depends_on_past': True,  # Training depends on previous successful runs
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=10),
}

# Define the DAG
with DAG(
    'ml_model_training',
    default_args=default_args,
    description='Weekly training and evaluation of ML prediction models',
    schedule_interval='0 2 * * 0',  # Run weekly on Sunday at 2 AM UTC
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['ml', 'training', 'models'],
    max_active_runs=1,
) as dag:

    # Task: Prepare training data
    prepare_data = PythonOperator(
        task_id='prepare_training_data',
        python_callable=prepare_training_data,
        provide_context=True,
    )

    # Task: Train NFL model
    train_nfl = PythonOperator(
        task_id='train_nfl_model',
        python_callable=train_nfl_model,
        provide_context=True,
    )

    # Task: Train NBA model
    train_nba = PythonOperator(
        task_id='train_nba_model',
        python_callable=train_nba_model,
        provide_context=True,
    )

    # Task: Train MLB model
    train_mlb = PythonOperator(
        task_id='train_mlb_model',
        python_callable=train_mlb_model,
        provide_context=True,
    )

    # Task: Evaluate models
    evaluate = PythonOperator(
        task_id='evaluate_models',
        python_callable=evaluate_models,
        provide_context=True,
    )

    # Task: Register in MLflow
    register_mlflow = PythonOperator(
        task_id='register_models_mlflow',
        python_callable=register_models_mlflow,
        provide_context=True,
    )

    # Task: Deploy models
    deploy = PythonOperator(
        task_id='deploy_models',
        python_callable=deploy_models,
        provide_context=True,
    )

    # Define task dependencies
    # Prepare data, then train all models in parallel, then evaluate, register, and deploy
    prepare_data >> [train_nfl, train_nba, train_mlb] >> evaluate >> register_mlflow >> deploy
