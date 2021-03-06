#!/usr/bin/env sh

# accepts: partner client ID and secret key, and some site info
# executes wp-cli command to provision Jetpack site for given partner

# TODO: 
# - allow user_email instead of user_id, automatically lookup/provision an admin on site (maybe rename user_id param to user?)

# change to script directory so that wp finds the wordpress install part for this Jetpack instance
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
cd $SCRIPT_DIR

usage () {
    echo "Usage: partner-provision.sh --partner_id=partner_id --partner_secret=partner_secret --user_id=wp_user_id --plan=plan_name"
}

for i in "$@"; do
    key="$1"
    case $i in
        -c=* | --partner_id=* )     CLIENT_ID="${i#*=}"
                                    shift
                                    ;;
        -s=* | --partner_secret=* ) CLIENT_SECRET="${i#*=}"
                                    shift
                                    ;;
        -i=* | --user_id=* )        WP_USER_ID="${i#*=}"
                                    shift
                                    ;;
        -p=* | --plan=* )           PLAN_NAME="${i#*=}"
                                    shift
                                    ;;
        -h | --help )               usage
                                    exit
                                    ;;
        * )                         usage
                                    exit 1
    esac
done

if [ "$CLIENT_ID" = "" ] || [ "$CLIENT_SECRET" = "" ] || [ "$PLAN_NAME" = "" ] || [ "$WP_USER_ID" = "" ]; then
    usage
    exit 1
fi

# default API host that can be overridden
if [ -z "$JETPACK_START_API_HOST" ]; then
    JETPACK_START_API_HOST='public-api.wordpress.com'
fi 

# fetch an access token using our client ID/secret
ACCESS_TOKEN_JSON=`curl https://$JETPACK_START_API_HOST/oauth2/token --silent --header "Host: public-api.wordpress.com" -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=jetpack-partner"`

# silently ensure Jetpack is active
wp plugin activate jetpack >/dev/null 2>&1

# provision the partner plan
wp jetpack partner_provision "$ACCESS_TOKEN_JSON" --user_id=$WP_USER_ID --plan=$PLAN_NAME

