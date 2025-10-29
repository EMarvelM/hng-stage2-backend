#!/bin/bash
# echo "Waiting 60 seconds for Railway to add database and redeploy..."
# sleep 60

echo ""
echo "Testing API endpoints..."
echo ""

# Test status
echo "1. Testing GET /status..."
curl -s https://hng-stage2-backend-production-a697.up.railway.app/status | jq '.'

echo ""
echo "2. Testing POST /countries/refresh..."
curl -s -X POST https://hng-stage2-backend-production-a697.up.railway.app/countries/refresh | jq '.'

echo ""
echo "3. Testing GET /countries (first 2)..."
curl -s https://hng-stage2-backend-production-a697.up.railway.app/countries | jq '.[0:2]'

echo ""
echo "4. Testing GET /countries/image..."
curl -s -I https://hng-stage2-backend-production-a697.up.railway.app/countries/image | grep -E "(HTTP|Content-Type)"

echo ""
echo "Done! If you see actual data (not errors), the database is working!"
