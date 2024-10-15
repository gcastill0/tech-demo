#!/bin/sh

# Path to the JSON file where we will write the environment variables
ENV_JSON_PATH="/var/www/localhost/htdocs/js/env_variables.json"

# Create a JSON file with the environment variables from the secret
cat <<EOF > $ENV_JSON_PATH
{
  "PREFIX": "${PREFIX}",
  "POSTFIX": "${POSTFIX}"
}
EOF

echo "Generated JSON file with environment variables:"
cat $ENV_JSON_PATH

chmod -R +r /var/www/localhost
chmod -R +x /var/www/localhost

# Start Apache in the foreground
exec httpd -DFOREGROUND
