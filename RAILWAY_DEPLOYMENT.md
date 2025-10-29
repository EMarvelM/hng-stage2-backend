# Railway Deployment Guide for HNG Stage 2 Backend

## Current Issue
The application is deployed but **Railway has NO MySQL database configured**. The logs show:
```
MYSQLHOST: 
MYSQL_HOST: 
DATABASE_URL: NOT SET
Using default connection string from appsettings.json
```

## Solution: Add MySQL Database to Railway

### Step 1: Add MySQL Database Service

1. Go to your Railway project dashboard: https://railway.app/project/YOUR_PROJECT_ID
2. Click **"+ New"** button
3. Select **"Database"**
4. Choose **"MySQL"**
5. Railway will create a new MySQL service

### Step 2: Link Database to Your Application

Railway will automatically provide these environment variables to your app once the database is linked:
- `MYSQLHOST` - Database host
- `MYSQLPORT` - Database port (usually 3306)
- `MYSQLUSER` - Database username
- `MYSQLDATABASE` - Database name
- `MYSQLPASSWORD` - Database password

OR it might provide:
- `DATABASE_URL` - Full connection string in format: `mysql://user:password@host:port/database`

### Step 3: Verify Environment Variables

1. In Railway, go to your **app service** (not the database)
2. Click on **"Variables"** tab
3. You should see the MySQL variables listed
4. If not, click **"Reference"** and select the MySQL database service to link them

### Step 4: Redeploy

Once the database is linked and variables are available:
1. Railway will automatically redeploy your application
2. Check the logs - you should see:
   ```
   Using Railway env vars: Server=XXXXX, Port=3306, Database=railway
   ```
3. The application should start successfully

## Testing After Deployment

Run the test script to verify all endpoints:
```bash
./test_api.sh
```

Expected results:
- POST /countries/refresh - Should fetch and store 250 countries
- GET /countries - Should return all countries
- GET /status - Should show total_countries > 0
- GET /countries/image - Should return a PNG image

## Alternative: Use Railway CLI

If you prefer using the CLI:

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link to your project
railway link

# Add MySQL database
railway add

# Check environment variables
railway variables

# View logs
railway logs
```

## Current Deployment URL
https://hng-stage2-backend-production-a697.up.railway.app

## Important Notes

1. **Database is required** - The app will crash without a database connection
2. **Environment variables are automatic** - Once database is linked, Railway provides them
3. **No manual configuration needed** - The app detects and uses Railway's variables
4. **Persistent storage** - Railway MySQL provides persistent data storage
5. **Free tier limits** - Railway free tier includes MySQL with limitations

## Troubleshooting

### App keeps crashing with "Unable to connect to MySQL"
- Ensure MySQL database service is created in Railway
- Check that database is linked to your app service
- Verify environment variables are present in app's Variables tab

### Database exists but connection fails
- Check Railway MySQL service status
- Verify MYSQLPASSWORD variable is set correctly
- Check if Railway MySQL is running in the same region

### Need to reset database
In Railway MySQL service dashboard:
1. Go to "Data" tab
2. Use the query interface to drop/recreate tables
3. Or delete and recreate the entire MySQL service
