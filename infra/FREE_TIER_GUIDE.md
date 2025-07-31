# Azure Free Tier Alternatives Guide

This guide explains how to deploy your Insight Vault infrastructure using Azure's free tier offerings to minimize costs during development and testing.

## 🆓 Free Tier Resources Available

### 1. **Azure Functions** - ✅ **FREE**
- **Free Tier**: 1 million executions per month
- **Memory**: 400,000 GB-seconds per month
- **Duration**: 60 seconds max execution time
- **Current Setup**: Uses Consumption plan (Y1) - pay-per-use
- **Free Alternative**: Already optimized, just monitor usage

### 2. **Cosmos DB** - ✅ **FREE**
- **Free Tier**: 1000 RU/s throughput + 25GB storage
- **Regions**: Single region only
- **Current Setup**: 400 RU/s + multi-region + analytical storage
- **Free Alternative**: 
  - Single region deployment
  - Disable analytical storage
  - Use 1000 RU/s (free tier limit)

### 3. **Storage Account** - ✅ **FREE**
- **Free Tier**: 5GB storage + 20,000 transactions per month
- **Current Setup**: Standard_LRS (already optimal)
- **Free Alternative**: Already using optimal SKU

### 4. **Static Web Apps** - ✅ **FREE**
- **Free Tier**: 2GB storage + 100GB bandwidth per month
- **Current Setup**: Already using Free tier
- **Free Alternative**: Already optimized

### 5. **Application Insights** - ✅ **FREE**
- **Free Tier**: 5GB data ingestion per month
- **Current Setup**: Already using basic tier
- **Free Alternative**: Already optimized

### 6. **App Service Plan** - ✅ **FREE**
- **Free Tier**: F1 tier (shared infrastructure)
- **Limitations**: 
  - 1GB RAM
  - 60 minutes/day CPU time
  - No custom domains
  - No SSL certificates
- **Current Setup**: Y1 (Consumption) - pay-per-use
- **Free Alternative**: F1 tier for development

### 7. **Virtual Network** - ❌ **NOT FREE**
- **Current Setup**: Custom VNet with subnets
- **Free Alternative**: Remove VNet entirely for free tier
- **Impact**: Functions will use default networking

## 🚀 How to Deploy Free Tier Version

### Option 1: Use Free Tier Parameters File
```bash
az deployment group create \
  --resource-group your-rg \
  --template-file infra/main.bicep \
  --parameters infra/parameters/free.bicepparam
```

### Option 2: Enable Free Tier Flag
```bash
az deployment group create \
  --resource-group your-rg \
  --template-file infra/main.bicep \
  --parameters infra/parameters/dev.bicepparam \
  --parameters enableFreeTier=true
```

## 📊 Cost Comparison

| Resource | Current Setup | Free Tier | Monthly Savings |
|----------|---------------|-----------|-----------------|
| Cosmos DB | ~$50-100 | $0 | $50-100 |
| Functions | ~$5-20 | $0 | $5-20 |
| Storage | ~$1-5 | $0 | $1-5 |
| VNet | ~$5-10 | $0 | $5-10 |
| **Total** | **~$60-135** | **$0** | **$60-135** |

## ⚠️ Free Tier Limitations

### App Service Plan (F1)
- **CPU Time**: 60 minutes per day
- **Memory**: 1GB RAM
- **Storage**: 1GB
- **Custom Domains**: Not supported
- **SSL**: Not supported
- **Scaling**: Not available

### Cosmos DB Free Tier
- **Throughput**: 1000 RU/s maximum
- **Storage**: 25GB maximum
- **Regions**: Single region only
- **Analytical Storage**: Not available
- **Backup**: Basic backup only

### Functions Free Tier
- **Executions**: 1 million per month
- **Memory**: 400,000 GB-seconds per month
- **Duration**: 60 seconds maximum
- **Concurrent Executions**: Limited

## 🔄 Migration Strategy

### Development → Production
1. **Start with Free Tier** for development
2. **Monitor usage** against free tier limits
3. **Upgrade gradually** as needed:
   - App Service: F1 → Y1 (Consumption)
   - Cosmos DB: Add regions, increase throughput
   - Add VNet for production security

### Recommended Approach
```bash
# Development (Free)
az deployment group create \
  --resource-group insight-vault-dev \
  --template-file infra/main.bicep \
  --parameters infra/parameters/free.bicepparam

# Production (Paid)
az deployment group create \
  --resource-group insight-vault-prod \
  --template-file infra/main.bicep \
  --parameters infra/parameters/prod.bicepparam
```

## 📈 Monitoring Free Tier Usage

### Azure Portal
1. Go to **Subscriptions** → **Usage + quotas**
2. Monitor usage against free tier limits
3. Set up alerts for approaching limits

### Azure CLI
```bash
# Check Cosmos DB usage
az cosmosdb show --name your-cosmos-account --resource-group your-rg

# Check Functions usage
az functionapp show --name your-function --resource-group your-rg
```

## 🎯 Best Practices

1. **Start Free**: Always begin with free tier for new projects
2. **Monitor Usage**: Set up alerts before hitting limits
3. **Gradual Scaling**: Upgrade resources incrementally
4. **Environment Separation**: Use different resource groups for dev/prod
5. **Cost Tracking**: Use Azure Cost Management to track spending

## 🔧 Troubleshooting

### Common Issues
- **Functions not starting**: Check F1 tier CPU time limits
- **Cosmos DB throttling**: Monitor RU/s usage
- **Storage quota exceeded**: Check 5GB free tier limit

### Solutions
- **Scale up**: Upgrade to paid tiers when needed
- **Optimize code**: Reduce function execution time
- **Clean up data**: Remove unused files from storage 