token=$(zign token)
team=buffalo
cat << __EOT__
ALTER ROLE admin NOLOGIN;
CREATE ROLE zalandos NOLOGIN;
__EOT__

echo "-- Team roles:"
curl --silent --request GET --header "Authorization: Bearer $token"  "https://teams.auth.zalando.com/api/teams/$team" \
  | jq -r '"CREATE USER " +.member[] +" WITH CREATEDB CREATEROLE IN ROLE zalandos, admin;"'
echo "-- Team ACID (dba) roles:"
curl --silent --request GET --header "Authorization: Bearer $token"  "https://teams.auth.zalando.com/api/teams/acid" \
  | jq -r '"CREATE USER " +.member[] +" SUPERUSER IN ROLE zalandos, admin;"'
