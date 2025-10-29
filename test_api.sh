#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_URL="https://hng-stage2-backend-production-a697.up.railway.app"

echo "============================================================"
echo "API Testing Script for HNG Stage 2 Backend"
echo "API URL: $API_URL"
echo "============================================================"
echo ""

# Test 1: POST /countries/refresh
echo "============================================================"
echo "TEST 1: POST /countries/refresh"
echo "============================================================"
echo "Sending POST request to refresh countries..."
REFRESH_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/countries/refresh")
REFRESH_HTTP_CODE=$(echo "$REFRESH_RESPONSE" | tail -n1)
REFRESH_BODY=$(echo "$REFRESH_RESPONSE" | sed '$d')

echo "HTTP Status Code: $REFRESH_HTTP_CODE"
echo "Response Body:"
echo "$REFRESH_BODY" | jq '.' 2>/dev/null || echo "$REFRESH_BODY"
echo ""

if [ "$REFRESH_HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Refresh endpoint returned 200${NC}"
else
    echo -e "${RED}✗ Refresh endpoint failed with status $REFRESH_HTTP_CODE${NC}"
fi
echo ""
sleep 2

# Test 2: GET /status
echo "============================================================"
echo "TEST 2: GET /status"
echo "============================================================"
echo "Checking status after refresh..."
STATUS_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/status")
STATUS_HTTP_CODE=$(echo "$STATUS_RESPONSE" | tail -n1)
STATUS_BODY=$(echo "$STATUS_RESPONSE" | sed '$d')

echo "HTTP Status Code: $STATUS_HTTP_CODE"
echo "Response Body:"
echo "$STATUS_BODY" | jq '.' 2>/dev/null || echo "$STATUS_BODY"
echo ""

TOTAL_COUNTRIES=$(echo "$STATUS_BODY" | jq -r '.total_countries' 2>/dev/null)
LAST_REFRESH=$(echo "$STATUS_BODY" | jq -r '.last_refreshed_at' 2>/dev/null)

echo "Total Countries: $TOTAL_COUNTRIES"
echo "Last Refresh: $LAST_REFRESH"
echo ""

if [ "$TOTAL_COUNTRIES" = "0" ] || [ "$TOTAL_COUNTRIES" = "null" ]; then
    echo -e "${RED}✗ No countries stored in database!${NC}"
    echo -e "${YELLOW}This indicates a database storage issue.${NC}"
else
    echo -e "${GREEN}✓ $TOTAL_COUNTRIES countries stored successfully${NC}"
fi
echo ""

# Test 3: GET /countries (basic)
echo "============================================================"
echo "TEST 3: GET /countries (all countries)"
echo "============================================================"
COUNTRIES_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/countries")
COUNTRIES_HTTP_CODE=$(echo "$COUNTRIES_RESPONSE" | tail -n1)
COUNTRIES_BODY=$(echo "$COUNTRIES_RESPONSE" | sed '$d')

echo "HTTP Status Code: $COUNTRIES_HTTP_CODE"
echo "Number of countries returned: $(echo "$COUNTRIES_BODY" | jq '. | length' 2>/dev/null || echo "0")"
echo "First 3 countries:"
echo "$COUNTRIES_BODY" | jq '.[0:3]' 2>/dev/null || echo "$COUNTRIES_BODY"
echo ""

# Test 4: GET /countries with filters
echo "============================================================"
echo "TEST 4: GET /countries?region=Africa"
echo "============================================================"
AFRICA_RESPONSE=$(curl -s "$API_URL/countries?region=Africa")
AFRICA_COUNT=$(echo "$AFRICA_RESPONSE" | jq '. | length' 2>/dev/null || echo "0")
echo "African countries found: $AFRICA_COUNT"
echo "$AFRICA_RESPONSE" | jq '.[0:2]' 2>/dev/null || echo "$AFRICA_RESPONSE"
echo ""

# Test 5: GET /countries with sorting
echo "============================================================"
echo "TEST 5: GET /countries?sort=gdp_desc"
echo "============================================================"
GDP_RESPONSE=$(curl -s "$API_URL/countries?sort=gdp_desc")
GDP_COUNT=$(echo "$GDP_RESPONSE" | jq '. | length' 2>/dev/null || echo "0")
echo "Countries sorted by GDP (top 3):"
echo "$GDP_RESPONSE" | jq '.[0:3] | .[] | {name: .name, estimated_gdp: .estimated_gdp}' 2>/dev/null || echo "$GDP_RESPONSE"
echo ""

# Test 6: GET /countries/:name
echo "============================================================"
echo "TEST 6: GET /countries/:name"
echo "============================================================"
# Try to get a specific country (e.g., Nigeria)
COUNTRY_NAME="Nigeria"
echo "Testing GET /countries/$COUNTRY_NAME"
COUNTRY_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/countries/$COUNTRY_NAME")
COUNTRY_HTTP_CODE=$(echo "$COUNTRY_RESPONSE" | tail -n1)
COUNTRY_BODY=$(echo "$COUNTRY_RESPONSE" | sed '$d')

echo "HTTP Status Code: $COUNTRY_HTTP_CODE"
echo "Response:"
echo "$COUNTRY_BODY" | jq '.' 2>/dev/null || echo "$COUNTRY_BODY"
echo ""

# Test 7: GET /countries/:name (non-existent)
echo "============================================================"
echo "TEST 7: GET /countries/:name (non-existent)"
echo "============================================================"
INVALID_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/countries/InvalidCountryName12345")
INVALID_HTTP_CODE=$(echo "$INVALID_RESPONSE" | tail -n1)
INVALID_BODY=$(echo "$INVALID_RESPONSE" | sed '$d')

echo "HTTP Status Code: $INVALID_HTTP_CODE"
echo "Response:"
echo "$INVALID_BODY" | jq '.' 2>/dev/null || echo "$INVALID_BODY"

if [ "$INVALID_HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✓ Returns 404 for non-existent country${NC}"
else
    echo -e "${RED}✗ Expected 404, got $INVALID_HTTP_CODE${NC}"
fi
echo ""

# Test 8: DELETE /countries/:name
echo "============================================================"
echo "TEST 8: DELETE /countries/:name (non-existent)"
echo "============================================================"
DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$API_URL/countries/InvalidCountryName12345")
DELETE_HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n1)
DELETE_BODY=$(echo "$DELETE_RESPONSE" | sed '$d')

echo "HTTP Status Code: $DELETE_HTTP_CODE"
echo "Response:"
echo "$DELETE_BODY" | jq '.' 2>/dev/null || echo "$DELETE_BODY"

if [ "$DELETE_HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✓ Returns 404 for deleting non-existent country${NC}"
else
    echo -e "${RED}✗ Expected 404, got $DELETE_HTTP_CODE${NC}"
fi
echo ""

# Test 9: GET /countries/image
echo "============================================================"
echo "TEST 9: GET /countries/image"
echo "============================================================"
IMAGE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\nCONTENT_TYPE:%{content_type}\nSIZE:%{size_download}" -o /tmp/country_summary.png "$API_URL/countries/image")
IMAGE_HTTP_CODE=$(echo "$IMAGE_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
IMAGE_CONTENT_TYPE=$(echo "$IMAGE_RESPONSE" | grep "CONTENT_TYPE:" | cut -d: -f2)
IMAGE_SIZE=$(echo "$IMAGE_RESPONSE" | grep "SIZE:" | cut -d: -f2)

echo "HTTP Status Code: $IMAGE_HTTP_CODE"
echo "Content-Type: $IMAGE_CONTENT_TYPE"
echo "Size: $IMAGE_SIZE bytes"

if [ "$IMAGE_HTTP_CODE" = "200" ] && [ "$IMAGE_CONTENT_TYPE" = "application/json; charset=utf-8" ]; then
    echo -e "${GREEN}✓ Image endpoint works correctly${NC}"
    echo "Summary data returned as JSON"
else
    echo -e "${RED}✗ Image endpoint failed${NC}"
fi
echo ""

# Summary
echo "============================================================"
echo "TEST SUMMARY"
echo "============================================================"
echo "Total Countries in DB: $TOTAL_COUNTRIES"
echo "Last Refresh: $LAST_REFRESH"
echo ""

if [ "$TOTAL_COUNTRIES" = "0" ] || [ "$TOTAL_COUNTRIES" = "null" ]; then
    echo -e "${RED}CRITICAL ISSUE: No countries stored after refresh!${NC}"
    echo ""
    echo "Possible causes:"
    echo "1. Database connection issue"
    echo "2. Transaction not being committed"
    echo "3. Exception during SaveChangesAsync()"
    echo "4. Database permissions issue"
    echo ""
    echo "Recommended actions:"
    echo "1. Check Railway logs for exceptions"
    echo "2. Verify DATABASE_URL environment variable"
    echo "3. Check if EnsureCreated() is running"
    echo "4. Add logging to RefreshCountriesAsync()"
else
    echo -e "${GREEN}SUCCESS: API appears to be working correctly!${NC}"
fi
echo "============================================================"
