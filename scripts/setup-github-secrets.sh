#!/bin/bash

# Script to help set up GitHub Secrets for CI/CD
# This script provides guidance and helper commands for setting up required secrets

set -e

REPO_OWNER="${GITHUB_REPOSITORY_OWNER:-sethpenn}"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-ml-stat-predictor}"

echo "=================================================="
echo "GitHub Secrets Setup Helper"
echo "=================================================="
echo ""
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo ""
    echo "Install it with:"
    echo "  macOS:   brew install gh"
    echo "  Linux:   See https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    echo "  Windows: See https://github.com/cli/cli/blob/trunk/docs/install_windows.md"
    echo ""
    echo "After installing, authenticate with: gh auth login"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Function to set secret
set_secret() {
    local secret_name=$1
    local secret_value=$2

    echo "$secret_value" | gh secret set "$secret_name" --repo "$REPO_OWNER/$REPO_NAME"

    if [ $? -eq 0 ]; then
        echo "✅ Secret $secret_name set successfully"
    else
        echo "❌ Failed to set secret $secret_name"
    fi
}

# Function to encode kubeconfig
encode_kubeconfig() {
    local kubeconfig_path=$1

    if [ ! -f "$kubeconfig_path" ]; then
        echo "❌ File not found: $kubeconfig_path"
        return 1
    fi

    cat "$kubeconfig_path" | base64
}

echo "=================================================="
echo "Setup Options"
echo "=================================================="
echo ""
echo "1. Set up Staging secrets"
echo "2. Set up Production secrets"
echo "3. Set up Codecov token"
echo "4. Set up notification webhooks"
echo "5. View current secrets"
echo "6. Exit"
echo ""
read -p "Choose an option (1-6): " option

case $option in
    1)
        echo ""
        echo "=================================================="
        echo "Setting up Staging Secrets"
        echo "=================================================="
        echo ""

        read -p "Path to staging kubeconfig (or press Enter to skip): " staging_kubeconfig

        if [ -n "$staging_kubeconfig" ]; then
            echo "Encoding kubeconfig..."
            encoded_config=$(encode_kubeconfig "$staging_kubeconfig")

            if [ -n "$encoded_config" ]; then
                set_secret "KUBE_CONFIG_STAGING" "$encoded_config"
            fi
        else
            echo "⚠️  Skipping KUBE_CONFIG_STAGING"
        fi

        echo ""
        read -p "Staging URL (e.g., https://staging.mlsp.example.com): " staging_url

        if [ -n "$staging_url" ]; then
            set_secret "STAGING_URL" "$staging_url"
        else
            echo "⚠️  Skipping STAGING_URL"
        fi

        echo ""
        echo "✅ Staging secrets setup complete"
        ;;

    2)
        echo ""
        echo "=================================================="
        echo "Setting up Production Secrets"
        echo "=================================================="
        echo ""

        read -p "Path to production kubeconfig (or press Enter to skip): " prod_kubeconfig

        if [ -n "$prod_kubeconfig" ]; then
            echo "Encoding kubeconfig..."
            encoded_config=$(encode_kubeconfig "$prod_kubeconfig")

            if [ -n "$encoded_config" ]; then
                set_secret "KUBE_CONFIG_PRODUCTION" "$encoded_config"
            fi
        else
            echo "⚠️  Skipping KUBE_CONFIG_PRODUCTION"
        fi

        echo ""
        read -p "Production URL (e.g., https://mlsp.example.com): " prod_url

        if [ -n "$prod_url" ]; then
            set_secret "PRODUCTION_URL" "$prod_url"
        else
            echo "⚠️  Skipping PRODUCTION_URL"
        fi

        echo ""
        echo "✅ Production secrets setup complete"
        ;;

    3)
        echo ""
        echo "=================================================="
        echo "Setting up Codecov Token"
        echo "=================================================="
        echo ""
        echo "Get your token from: https://codecov.io/gh/$REPO_OWNER/$REPO_NAME/settings"
        echo ""
        read -p "Codecov token (or press Enter to skip): " codecov_token

        if [ -n "$codecov_token" ]; then
            set_secret "CODECOV_TOKEN" "$codecov_token"
            echo "✅ Codecov token set"
        else
            echo "⚠️  Skipping CODECOV_TOKEN"
        fi
        ;;

    4)
        echo ""
        echo "=================================================="
        echo "Setting up Notification Webhooks"
        echo "=================================================="
        echo ""

        read -p "Slack webhook URL (or press Enter to skip): " slack_webhook

        if [ -n "$slack_webhook" ]; then
            set_secret "SLACK_WEBHOOK_URL" "$slack_webhook"
        else
            echo "⚠️  Skipping SLACK_WEBHOOK_URL"
        fi

        echo ""
        read -p "Discord webhook URL (or press Enter to skip): " discord_webhook

        if [ -n "$discord_webhook" ]; then
            set_secret "DISCORD_WEBHOOK_URL" "$discord_webhook"
        else
            echo "⚠️  Skipping DISCORD_WEBHOOK_URL"
        fi

        echo ""
        echo "✅ Notification webhooks setup complete"
        ;;

    5)
        echo ""
        echo "=================================================="
        echo "Current Secrets"
        echo "=================================================="
        echo ""
        gh secret list --repo "$REPO_OWNER/$REPO_NAME"
        ;;

    6)
        echo "Exiting..."
        exit 0
        ;;

    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "=================================================="
echo "Next Steps"
echo "=================================================="
echo ""
echo "1. Set up GitHub Environments:"
echo "   - Go to: https://github.com/$REPO_OWNER/$REPO_NAME/settings/environments"
echo "   - Create environments: staging, production, production-rollback"
echo "   - Configure protection rules and required reviewers"
echo ""
echo "2. Verify secrets are set:"
echo "   - Run this script again and select option 5"
echo ""
echo "3. Test the workflows:"
echo "   - Create a test PR to trigger pr.yml"
echo "   - Merge to main to trigger main.yml"
echo "   - Use Actions tab to test deploy-production.yml"
echo ""
echo "See docs/CI-CD.md for detailed documentation"
echo ""
