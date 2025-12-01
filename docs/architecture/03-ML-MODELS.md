# Machine Learning Models Specification

## Overview

This document details the machine learning architecture for predicting sports game outcomes and player statistics. The system employs an ensemble approach combining multiple model types for optimal prediction accuracy.

## Prediction Categories

### 1. Game Outcome Predictions
- **Win/Loss Classification** - Binary prediction of game winner
- **Point Spread Prediction** - Regression for margin of victory
- **Over/Under Prediction** - Total points regression + classification

### 2. Player Performance Predictions
- **Stat-specific Regression** - Points, rebounds, assists, etc.
- **Prop Bet Predictions** - Over/under on individual stat lines
- **Performance Tiers** - Classification into performance buckets

## Feature Engineering

### Game-Level Features

```python
# ml/features/game_features.py
from typing import List, Dict
import pandas as pd
import numpy as np

class GameFeatureGenerator:
    """Generate features for game-level predictions."""

    def __init__(self, lookback_games: int = 10):
        self.lookback = lookback_games

    def generate_features(self, game_id: int, df: pd.DataFrame) -> Dict:
        """Generate all features for a single game prediction."""
        features = {}

        # Team performance features
        features.update(self.team_rolling_stats(game_id, df, 'home'))
        features.update(self.team_rolling_stats(game_id, df, 'away'))

        # Head-to-head features
        features.update(self.head_to_head_features(game_id, df))

        # Situational features
        features.update(self.situational_features(game_id, df))

        # Rest and schedule features
        features.update(self.rest_features(game_id, df))

        return features

    def team_rolling_stats(self, game_id: int, df: pd.DataFrame, side: str) -> Dict:
        """Calculate rolling statistics for team performance."""
        prefix = f'{side}_'
        team_games = self.get_team_recent_games(game_id, df, side)

        return {
            f'{prefix}win_pct_l10': team_games['win'].mean(),
            f'{prefix}ppg_l10': team_games['points_for'].mean(),
            f'{prefix}opp_ppg_l10': team_games['points_against'].mean(),
            f'{prefix}margin_l10': team_games['margin'].mean(),
            f'{prefix}off_rating_l10': team_games['offensive_rating'].mean(),
            f'{prefix}def_rating_l10': team_games['defensive_rating'].mean(),
            f'{prefix}pace_l10': team_games['pace'].mean(),
            f'{prefix}home_win_pct': team_games[team_games['is_home']]['win'].mean(),
            f'{prefix}away_win_pct': team_games[~team_games['is_home']]['win'].mean(),
            f'{prefix}streak': self.calculate_streak(team_games),
        }

    def head_to_head_features(self, game_id: int, df: pd.DataFrame) -> Dict:
        """Calculate head-to-head historical features."""
        h2h_games = self.get_h2h_games(game_id, df)

        if len(h2h_games) == 0:
            return {
                'h2h_home_win_pct': 0.5,
                'h2h_avg_margin': 0,
                'h2h_games_played': 0,
            }

        return {
            'h2h_home_win_pct': h2h_games['home_win'].mean(),
            'h2h_avg_margin': h2h_games['margin'].mean(),
            'h2h_games_played': len(h2h_games),
            'h2h_last_winner': h2h_games.iloc[-1]['winner'],
        }

    def situational_features(self, game_id: int, df: pd.DataFrame) -> Dict:
        """Generate situational context features."""
        game = df.loc[game_id]

        return {
            'is_playoff': int(game['is_playoff']),
            'day_of_week': game['game_date'].dayofweek,
            'month': game['game_date'].month,
            'is_division_game': int(game['home_division'] == game['away_division']),
            'is_conference_game': int(game['home_conference'] == game['away_conference']),
        }

    def rest_features(self, game_id: int, df: pd.DataFrame) -> Dict:
        """Calculate rest days and schedule density."""
        game = df.loc[game_id]

        return {
            'home_rest_days': self.days_since_last_game(game_id, df, 'home'),
            'away_rest_days': self.days_since_last_game(game_id, df, 'away'),
            'home_games_in_week': self.games_in_last_n_days(game_id, df, 'home', 7),
            'away_games_in_week': self.games_in_last_n_days(game_id, df, 'away', 7),
            'home_back_to_back': int(self.days_since_last_game(game_id, df, 'home') <= 1),
            'away_back_to_back': int(self.days_since_last_game(game_id, df, 'away') <= 1),
        }
```

### Player-Level Features

```python
# ml/features/player_features.py
class PlayerFeatureGenerator:
    """Generate features for player stat predictions."""

    def generate_features(self, player_id: int, game_id: int, df: pd.DataFrame) -> Dict:
        """Generate features for player performance prediction."""
        features = {}

        # Player historical performance
        features.update(self.player_rolling_stats(player_id, df))

        # Matchup-specific features
        features.update(self.matchup_features(player_id, game_id, df))

        # Usage and role features
        features.update(self.usage_features(player_id, df))

        # Teammate context
        features.update(self.teammate_features(player_id, game_id, df))

        return features

    def player_rolling_stats(self, player_id: int, df: pd.DataFrame) -> Dict:
        """Rolling averages of player statistics."""
        player_games = df[df['player_id'] == player_id].tail(20)

        stats = ['points', 'rebounds', 'assists', 'minutes', 'usage_rate']
        features = {}

        for stat in stats:
            if stat in player_games.columns:
                features[f'{stat}_avg_l5'] = player_games.tail(5)[stat].mean()
                features[f'{stat}_avg_l10'] = player_games.tail(10)[stat].mean()
                features[f'{stat}_avg_l20'] = player_games[stat].mean()
                features[f'{stat}_std_l10'] = player_games.tail(10)[stat].std()
                features[f'{stat}_trend'] = self.calculate_trend(player_games[stat])

        return features

    def matchup_features(self, player_id: int, game_id: int, df: pd.DataFrame) -> Dict:
        """Features based on opponent matchup."""
        game = df.loc[game_id]
        opponent = game['opponent_id']

        # Historical performance vs this opponent
        vs_opponent = df[(df['player_id'] == player_id) & (df['opponent_id'] == opponent)]

        return {
            'vs_opp_pts_avg': vs_opponent['points'].mean() if len(vs_opponent) > 0 else None,
            'vs_opp_games': len(vs_opponent),
            'opp_def_rating': game['opponent_def_rating'],
            'opp_pace': game['opponent_pace'],
            'opp_position_defense': self.get_position_defense(player_id, opponent, df),
        }

    def usage_features(self, player_id: int, df: pd.DataFrame) -> Dict:
        """Player usage and role metrics."""
        recent_games = df[df['player_id'] == player_id].tail(10)

        return {
            'avg_minutes': recent_games['minutes'].mean(),
            'minutes_trend': self.calculate_trend(recent_games['minutes']),
            'usage_rate': recent_games['usage_rate'].mean(),
            'is_starter': int(recent_games['is_starter'].mode()[0]),
            'touch_rate': recent_games['touches_per_min'].mean(),
        }
```

## Model Architecture

### 1. Game Outcome Model (XGBoost Ensemble)

```python
# ml/models/game_outcome.py
import xgboost as xgb
from sklearn.model_selection import TimeSeriesSplit
from sklearn.metrics import accuracy_score, log_loss
import numpy as np

class GameOutcomeModel:
    """XGBoost classifier for game win/loss prediction."""

    def __init__(self):
        self.model = xgb.XGBClassifier(
            n_estimators=500,
            max_depth=6,
            learning_rate=0.05,
            subsample=0.8,
            colsample_bytree=0.8,
            min_child_weight=3,
            reg_alpha=0.1,
            reg_lambda=1.0,
            objective='binary:logistic',
            eval_metric='logloss',
            early_stopping_rounds=50,
            random_state=42,
        )
        self.feature_columns = None
        self.calibrator = None

    def train(self, X: pd.DataFrame, y: pd.Series, eval_set=None):
        """Train the model with time-series cross-validation."""
        self.feature_columns = X.columns.tolist()

        # Use time series split to respect temporal ordering
        tscv = TimeSeriesSplit(n_splits=5)

        # Train final model
        self.model.fit(
            X, y,
            eval_set=eval_set,
            verbose=100,
        )

        # Calibrate probabilities
        self._calibrate_probabilities(X, y)

    def predict(self, X: pd.DataFrame) -> np.ndarray:
        """Predict win probability."""
        X = X[self.feature_columns]
        proba = self.model.predict_proba(X)[:, 1]

        if self.calibrator:
            proba = self.calibrator.transform(proba)

        return proba

    def get_feature_importance(self) -> pd.DataFrame:
        """Return feature importance rankings."""
        importance = self.model.feature_importances_
        return pd.DataFrame({
            'feature': self.feature_columns,
            'importance': importance,
        }).sort_values('importance', ascending=False)


class PointSpreadModel:
    """Gradient boosting regressor for point spread prediction."""

    def __init__(self):
        self.model = xgb.XGBRegressor(
            n_estimators=500,
            max_depth=5,
            learning_rate=0.05,
            subsample=0.8,
            colsample_bytree=0.8,
            reg_alpha=0.1,
            reg_lambda=1.0,
            objective='reg:squarederror',
            early_stopping_rounds=50,
            random_state=42,
        )

    def train(self, X: pd.DataFrame, y: pd.Series, eval_set=None):
        """Train the point spread model."""
        self.model.fit(X, y, eval_set=eval_set, verbose=100)

    def predict(self, X: pd.DataFrame) -> np.ndarray:
        """Predict point spread (positive = home team favored)."""
        return self.model.predict(X)
```

### 2. Player Performance Model (Neural Network)

```python
# ml/models/player_stats.py
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset

class PlayerStatPredictor(nn.Module):
    """Neural network for player stat prediction."""

    def __init__(self, input_dim: int, output_dim: int = 1):
        super().__init__()

        self.network = nn.Sequential(
            nn.Linear(input_dim, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(),
            nn.Dropout(0.3),

            nn.Linear(256, 128),
            nn.BatchNorm1d(128),
            nn.ReLU(),
            nn.Dropout(0.2),

            nn.Linear(128, 64),
            nn.BatchNorm1d(64),
            nn.ReLU(),
            nn.Dropout(0.1),

            nn.Linear(64, output_dim),
        )

    def forward(self, x):
        return self.network(x)


class PlayerStatTrainer:
    """Training pipeline for player stat models."""

    def __init__(self, model: PlayerStatPredictor, lr: float = 0.001):
        self.model = model
        self.optimizer = torch.optim.Adam(model.parameters(), lr=lr)
        self.criterion = nn.MSELoss()
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.model.to(self.device)

    def train(self, train_loader: DataLoader, val_loader: DataLoader, epochs: int = 100):
        """Train the model with early stopping."""
        best_val_loss = float('inf')
        patience = 10
        patience_counter = 0

        for epoch in range(epochs):
            # Training phase
            self.model.train()
            train_loss = 0
            for X_batch, y_batch in train_loader:
                X_batch = X_batch.to(self.device)
                y_batch = y_batch.to(self.device)

                self.optimizer.zero_grad()
                predictions = self.model(X_batch)
                loss = self.criterion(predictions, y_batch)
                loss.backward()
                self.optimizer.step()

                train_loss += loss.item()

            # Validation phase
            val_loss = self.evaluate(val_loader)

            # Early stopping check
            if val_loss < best_val_loss:
                best_val_loss = val_loss
                patience_counter = 0
                self.save_checkpoint()
            else:
                patience_counter += 1
                if patience_counter >= patience:
                    print(f'Early stopping at epoch {epoch}')
                    self.load_checkpoint()
                    break

    def evaluate(self, loader: DataLoader) -> float:
        """Evaluate model on validation set."""
        self.model.eval()
        total_loss = 0

        with torch.no_grad():
            for X_batch, y_batch in loader:
                X_batch = X_batch.to(self.device)
                y_batch = y_batch.to(self.device)
                predictions = self.model(X_batch)
                loss = self.criterion(predictions, y_batch)
                total_loss += loss.item()

        return total_loss / len(loader)
```

### 3. Ensemble Model

```python
# ml/models/ensemble.py
from typing import List, Dict
import numpy as np

class PredictionEnsemble:
    """Combine multiple models for final predictions."""

    def __init__(self, models: Dict[str, object], weights: Dict[str, float] = None):
        self.models = models
        self.weights = weights or {name: 1.0 / len(models) for name in models}

    def predict_game_outcome(self, features: pd.DataFrame) -> Dict:
        """Generate ensemble game outcome prediction."""
        predictions = {}

        # Get predictions from each model
        for name, model in self.models.items():
            if hasattr(model, 'predict_proba'):
                predictions[name] = model.predict_proba(features)[:, 1]
            else:
                predictions[name] = model.predict(features)

        # Weighted average
        ensemble_prob = np.zeros(len(features))
        for name, pred in predictions.items():
            ensemble_prob += self.weights[name] * pred

        return {
            'win_probability': ensemble_prob,
            'individual_predictions': predictions,
            'confidence': self.calculate_confidence(predictions),
        }

    def calculate_confidence(self, predictions: Dict[str, np.ndarray]) -> np.ndarray:
        """Calculate prediction confidence based on model agreement."""
        pred_values = np.array(list(predictions.values()))
        # Lower std = higher agreement = higher confidence
        agreement = 1 - pred_values.std(axis=0)
        # Scale to 0-1
        return agreement
```

## Model Training Pipeline

### Training DAG

```python
# dags/model_training.py
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

with DAG(
    'weekly_model_training',
    description='Weekly retraining of ML models',
    schedule_interval='0 0 * * 0',  # Every Sunday at midnight
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['ml', 'training'],
) as dag:

    prepare_training_data = PythonOperator(
        task_id='prepare_training_data',
        python_callable=prepare_data_for_training,
    )

    train_game_outcome = PythonOperator(
        task_id='train_game_outcome_model',
        python_callable=train_game_outcome_model,
    )

    train_point_spread = PythonOperator(
        task_id='train_point_spread_model',
        python_callable=train_point_spread_model,
    )

    train_player_models = PythonOperator(
        task_id='train_player_stat_models',
        python_callable=train_player_models,
    )

    evaluate_models = PythonOperator(
        task_id='evaluate_all_models',
        python_callable=evaluate_models,
    )

    register_models = PythonOperator(
        task_id='register_in_mlflow',
        python_callable=register_models_mlflow,
    )

    deploy_if_improved = PythonOperator(
        task_id='deploy_if_improved',
        python_callable=conditional_deployment,
    )

    prepare_training_data >> [train_game_outcome, train_point_spread, train_player_models]
    [train_game_outcome, train_point_spread, train_player_models] >> evaluate_models
    evaluate_models >> register_models >> deploy_if_improved
```

### MLflow Integration

```python
# ml/tracking/mlflow_integration.py
import mlflow
import mlflow.sklearn
import mlflow.pytorch
from typing import Dict, Any

class ExperimentTracker:
    """MLflow experiment tracking wrapper."""

    def __init__(self, experiment_name: str):
        mlflow.set_tracking_uri("http://mlflow:5000")
        mlflow.set_experiment(experiment_name)

    def log_training_run(
        self,
        model: Any,
        params: Dict,
        metrics: Dict,
        artifacts: Dict = None,
        model_type: str = 'sklearn'
    ):
        """Log a complete training run."""
        with mlflow.start_run():
            # Log parameters
            mlflow.log_params(params)

            # Log metrics
            mlflow.log_metrics(metrics)

            # Log model
            if model_type == 'sklearn':
                mlflow.sklearn.log_model(model, "model")
            elif model_type == 'pytorch':
                mlflow.pytorch.log_model(model, "model")
            elif model_type == 'xgboost':
                mlflow.xgboost.log_model(model, "model")

            # Log additional artifacts
            if artifacts:
                for name, path in artifacts.items():
                    mlflow.log_artifact(path, name)

            return mlflow.active_run().info.run_id

    def load_production_model(self, model_name: str):
        """Load the current production model."""
        model_uri = f"models:/{model_name}/Production"
        return mlflow.pyfunc.load_model(model_uri)

    def promote_to_production(self, model_name: str, run_id: str):
        """Promote a model to production stage."""
        client = mlflow.tracking.MlflowClient()
        model_version = client.create_model_version(
            name=model_name,
            source=f"runs:/{run_id}/model",
            run_id=run_id,
        )
        client.transition_model_version_stage(
            name=model_name,
            version=model_version.version,
            stage="Production",
        )
```

## Model Evaluation

### Evaluation Metrics

```python
# ml/evaluation/metrics.py
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    roc_auc_score, log_loss, mean_absolute_error, mean_squared_error
)
import numpy as np

class ModelEvaluator:
    """Comprehensive model evaluation."""

    def evaluate_classifier(self, y_true, y_pred, y_prob=None) -> Dict:
        """Evaluate classification model."""
        metrics = {
            'accuracy': accuracy_score(y_true, y_pred),
            'precision': precision_score(y_true, y_pred),
            'recall': recall_score(y_true, y_pred),
            'f1': f1_score(y_true, y_pred),
        }

        if y_prob is not None:
            metrics['roc_auc'] = roc_auc_score(y_true, y_prob)
            metrics['log_loss'] = log_loss(y_true, y_prob)

        return metrics

    def evaluate_regressor(self, y_true, y_pred) -> Dict:
        """Evaluate regression model."""
        return {
            'mae': mean_absolute_error(y_true, y_pred),
            'rmse': np.sqrt(mean_squared_error(y_true, y_pred)),
            'mape': np.mean(np.abs((y_true - y_pred) / y_true)) * 100,
            'r2': 1 - (np.sum((y_true - y_pred)**2) / np.sum((y_true - np.mean(y_true))**2)),
        }

    def evaluate_spread_prediction(self, y_true, y_pred) -> Dict:
        """Evaluate point spread predictions."""
        # Check if prediction got the correct side
        correct_side = np.sign(y_true) == np.sign(y_pred)

        return {
            'mae': mean_absolute_error(y_true, y_pred),
            'correct_side_pct': correct_side.mean(),
            'within_3_pts': (np.abs(y_true - y_pred) <= 3).mean(),
            'within_5_pts': (np.abs(y_true - y_pred) <= 5).mean(),
            'within_7_pts': (np.abs(y_true - y_pred) <= 7).mean(),
        }

    def calculate_betting_metrics(self, predictions: pd.DataFrame) -> Dict:
        """Calculate hypothetical betting performance."""
        # Assume betting when confidence > threshold
        confident_bets = predictions[predictions['confidence'] > 0.6]

        return {
            'total_bets': len(confident_bets),
            'win_rate': (confident_bets['correct']).mean(),
            'roi': self.calculate_roi(confident_bets),
            'sharpe_ratio': self.calculate_sharpe(confident_bets),
        }
```

### A/B Testing Framework

```python
# ml/evaluation/ab_testing.py
class ModelABTest:
    """Framework for A/B testing model versions."""

    def __init__(self, model_a, model_b, traffic_split: float = 0.5):
        self.model_a = model_a
        self.model_b = model_b
        self.traffic_split = traffic_split
        self.results = {'a': [], 'b': []}

    def get_prediction(self, features: pd.DataFrame) -> Dict:
        """Get prediction from one of the models based on traffic split."""
        use_b = np.random.random() < self.traffic_split
        model = self.model_b if use_b else self.model_a
        model_name = 'b' if use_b else 'a'

        prediction = model.predict(features)

        return {
            'model': model_name,
            'prediction': prediction,
        }

    def record_outcome(self, model_name: str, prediction: float, actual: float):
        """Record prediction outcome for analysis."""
        self.results[model_name].append({
            'prediction': prediction,
            'actual': actual,
            'error': abs(prediction - actual),
        })

    def analyze_results(self) -> Dict:
        """Statistical analysis of A/B test results."""
        from scipy import stats

        errors_a = [r['error'] for r in self.results['a']]
        errors_b = [r['error'] for r in self.results['b']]

        # T-test for significance
        t_stat, p_value = stats.ttest_ind(errors_a, errors_b)

        return {
            'model_a_mean_error': np.mean(errors_a),
            'model_b_mean_error': np.mean(errors_b),
            'improvement': (np.mean(errors_a) - np.mean(errors_b)) / np.mean(errors_a),
            'p_value': p_value,
            'significant': p_value < 0.05,
            'sample_size_a': len(errors_a),
            'sample_size_b': len(errors_b),
        }
```

## Model Serving

### Inference Service

```python
# ml/inference/predictor.py
from typing import Dict, List
import numpy as np
from functools import lru_cache

class PredictionService:
    """Production inference service."""

    def __init__(self):
        self.models = {}
        self.feature_generators = {}
        self.load_models()

    @lru_cache(maxsize=100)
    def predict_game(self, game_id: int) -> Dict:
        """Generate all predictions for a game."""
        features = self.feature_generators['game'].generate(game_id)

        return {
            'game_id': game_id,
            'predictions': {
                'win_probability': {
                    'home': float(self.models['game_outcome'].predict(features)[0]),
                    'away': float(1 - self.models['game_outcome'].predict(features)[0]),
                },
                'point_spread': float(self.models['point_spread'].predict(features)[0]),
                'total_points': float(self.models['total_points'].predict(features)[0]),
            },
            'confidence': self.calculate_confidence(features),
            'model_version': self.get_model_version(),
        }

    def predict_player_stats(self, player_id: int, game_id: int) -> Dict:
        """Predict player statistics for a game."""
        features = self.feature_generators['player'].generate(player_id, game_id)

        predictions = {}
        for stat in ['points', 'rebounds', 'assists']:
            model = self.models[f'player_{stat}']
            predictions[stat] = {
                'predicted': float(model.predict(features)[0]),
                'confidence_interval': self.get_confidence_interval(model, features),
            }

        return {
            'player_id': player_id,
            'game_id': game_id,
            'predictions': predictions,
        }

    def batch_predict(self, game_ids: List[int]) -> List[Dict]:
        """Batch prediction for multiple games."""
        return [self.predict_game(gid) for gid in game_ids]
```

## Target Metrics

| Model | Metric | Target | Current |
|-------|--------|--------|---------|
| Game Outcome (Win/Loss) | Accuracy | > 60% | - |
| Game Outcome (Win/Loss) | ROC-AUC | > 0.65 | - |
| Point Spread | MAE | < 5 pts | - |
| Point Spread | Correct Side % | > 55% | - |
| Player Points | MAPE | < 25% | - |
| Player Rebounds | MAPE | < 30% | - |
| Player Assists | MAPE | < 30% | - |
