#!/bin/bash

set -e

# source .env

# ==================
# == Env settings ==
# ==================

# check operating system
SED_COMMAND() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "$@"
    else
        # not macOS
        sed -i "$@"
    fi
}

show_message() {
    echo "$@"
}

# ==========================
# === Regenerate Secrets ===
# ==========================
section_regenerate_secrets() {
    # Check if openssl is installed
    if ! command -v openssl &> /dev/null ; then
        echo "openssl" $(show_message "tips_no_executable")
        exit 1
    fi
    if ! command -v tr &> /dev/null ; then
        echo "tr" $(show_message "tips_no_executable")
        exit 1
    fi
    if ! command -v fold &> /dev/null ; then
        echo "fold" $(show_message "tips_no_executable")
        exit 1
    fi
    if ! command -v head &> /dev/null ; then
        echo "head" $(show_message "tips_no_executable")
        exit 1
    fi

    generate_key() {
        if [[ -z "$1" ]]; then
            echo "Usage: generate_key <length>"
            return 1
        fi
        echo $(openssl rand -hex $1 | tr -d '\n' | fold -w $1 | head -n 1)
    }

    if ! command -v sed &> /dev/null ; then
        echo "sed" $(show_message "tips_no_executable")
        exit 1
    fi
    echo $(show_message "security_secrect_regenerate")

    # Generate CASDOOR_SECRET
    CASDOOR_SECRET=$(generate_key 32)
    if [ $? -ne 0 ]; then
        echo $(show_message "security_secrect_regenerate_failed") "CASDOOR_SECRET"
    else
        # Search and replace the value of CASDOOR_SECRET in .env
        SED_COMMAND "s#^AUTH_CASDOOR_SECRET=.*#AUTH_CASDOOR_SECRET=${CASDOOR_SECRET}#" .env
        if [ $? -ne 0 ]; then
            echo $(show_message "security_secrect_regenerate_failed") "AUTH_CASDOOR_SECRET in \`.env\`"
        fi
        # replace `clientSecrect` in init_data.json
        SED_COMMAND "s#__CASDOOR_CLIENT_SECRET__#${CASDOOR_SECRET}#" init_data.json
        if [ $? -ne 0 ]; then
            echo $(show_message "security_secrect_regenerate_failed") "CASDOOR_CLIENT_SECRET in \`init_data.json\`"
        fi
    fi

    # Generate Casdoor User
    CASDOOR_USER="admin"
    CASDOOR_PASSWORD=$(generate_key 10)
    if [ $? -ne 0 ]; then
        echo $(show_message "security_secrect_regenerate_failed") "CASDOOR_PASSWORD"
        CASDOOR_PASSWORD="Qingling@123"
    else
        # replace `password` in init_data.json
        SED_COMMAND "s/"__CASDOOR_PASSWORD__"/${CASDOOR_PASSWORD}/" init_data.json
        if [ $? -ne 0 ]; then
            echo $(show_message "security_secrect_regenerate_failed") "CASDOOR_PASSWORD in \`init_data.json\`"
        fi
    fi

    # Generate Minio S3 User Password
    MINIO_ROOT_PASSWORD=$(generate_key 8)
    if [ $? -ne 0 ]; then
        echo $(show_message "security_secrect_regenerate_failed") "MINIO_ROOT_PASSWORD"
        MINIO_ROOT_PASSWORD="YOUR_MINIO_PASSWORD"
    else
        # Search and replace the value of S3_SECRET_ACCESS_KEY in .env
        SED_COMMAND "s#^MINIO_ROOT_PASSWORD=.*#MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}#" .env
        if [ $? -ne 0 ]; then
            echo $(show_message "security_secrect_regenerate_failed") "MINIO_ROOT_PASSWORD in \`.env\`"
        fi
    fi

    # Generate access code
    ACCESS_CODE=$(openssl rand -base64 20 | tr -dc 'a-zA-Z0-9_@!' | head -c 16)
    if [ $? -ne 0 ]; then
        echo $(show_message "security_secrect_regenerate_failed") "ACCESS_CODE"
        ACCESS_CODE="YOUR_ACCESS_CODE"
    else
        # Search and replace the value of S3_SECRET_ACCESS_KEY in .env
        SED_COMMAND "s#^ACCESS_CODE=.*#ACCESS_CODE=${ACCESS_CODE}#" .env
        if [ $? -ne 0 ]; then
            echo $(show_message "security_secrect_regenerate_failed") "ACCESS_CODE in \`.env\`"
        fi
    fi

    # Generate key vaults secret
    KEY_VAULTS_SECRET=$(openssl rand -base64 32)
    if [ $? -ne 0 ]; then
        echo $(show_message "security_secrect_regenerate_failed") "KEY_VAULTS_SECRET"
        KEY_VAULTS_SECRET="YOUR_KEY_VAULTS_SECRET"
    else
        # Search and replace the value of S3_SECRET_ACCESS_KEY in .env
        SED_COMMAND "s#^KEY_VAULTS_SECRET=.*#KEY_VAULTS_SECRET=${KEY_VAULTS_SECRET}#" .env
        if [ $? -ne 0 ]; then
            echo $(show_message "security_secrect_regenerate_failed") "KEY_VAULTS_SECRET in \`.env\`"
        fi
    fi

    # Generate next_auth_secret
    NEXT_AUTH_SECRET=$(openssl rand -base64 20 | tr -dc 'a-zA-Z0-9_@!' | head -c 16)
    if [ $? -ne 0 ]; then
        echo $(show_message "security_secrect_regenerate_failed") "NEXT_AUTH_SECRET"
        NEXT_AUTH_SECRET="YOUR_NEXT_AUTH_SECRET"
    else
        # Search and replace the value of S3_SECRET_ACCESS_KEY in .env
        SED_COMMAND "s#^NEXT_AUTH_SECRET=.*#NEXT_AUTH_SECRET=${NEXT_AUTH_SECRET}#" .env
        if [ $? -ne 0 ]; then
            echo $(show_message "security_secrect_regenerate_failed") "NEXT_AUTH_SECRET in \`.env\`"
        fi
    fi
}

section_regenerate_redirect_uris() {
    #  Regenerate redirect URIs
    source .env
    redirect_uri=${AUTH_URL}/callback/casdoor
    SED_COMMAND "s#__CASDOOR_REDIRECT_URI__#${redirect_uri}#" init_data.json
    if [ $? -ne 0 ]; then
        echo $(show_message "section_regenerate_redirect_uris_failed") "CASDOOR_REDIRECT_URI in \`init_data.json\`"
    fi
}

section_display_configurated_report() {
    # Display configuration reports
    echo $(show_message "security_secrect_regenerate_report")

    source .env
    LOBE_HOST=$APP_HOST
    MINIO_HOST=$APP_HOST:$MINIO_PORT
    CASDOOR_HOST=$APP_HOST:$CASDOOR_PORT
    QINGLING_PASSWORD=Qingling@123
    echo -e "LobeChat: \n  - URL: $APP_URL \n  - Username: qingling \n  - Password: ${QINGLING_PASSWORD} "
    echo -e "Casdoor: \n  - URL: $CASDOOR_HOST \n  - Username: admin \n  - Password: ${CASDOOR_PASSWORD}\n"
    echo -e "Minio: \n  - URL: $MINIO_HOST \n  - Username: admin\n  - Password: ${MINIO_ROOT_PASSWORD}\n"

    # # if user run in domain mode, diplay reverse proxy configuration
    # if [[ "$DEPLOY_MODE" == "domain" ]]; then
    #     echo $(show_message "tips_add_reverse_proxy")
    #     printf "\n%s\t->\t%s\n" "$LOBE_HOST" "127.0.0.1:3210"
    #     printf "%s\t->\t%s\n" "$CASDOOR_HOST" "127.0.0.1:8000"
    #     printf "%s\t->\t%s\n" "$MINIO_HOST" "127.0.0.1:9000"
    # fi
}

section_init_database() {
    if ! command -v docker &> /dev/null ; then
        echo "docker" $(show_message "tips_no_executable")
	    return 1
    fi

    if ! docker compose &> /dev/null ; then
	    echo "docker compose" $(show_message "tips_no_executable")
	    return 1
    fi

    # Check if user has permissions to run Docker by trying to get the status of Docker (docker status).
    # If this fails, the user probably does not have permissions for Docker.
    # ref: https://github.com/paperless-ngx/paperless-ngx/blob/89e5c08a1fe4ca0b7641ae8fbd5554502199ae40/install-paperless-ngx.sh#L64-L72
    if ! docker stats --no-stream &> /dev/null ; then
	    echo $(show_message "tips_no_docker_permission")
	    return 1
    fi

    docker compose pull
    docker compose up --detach postgresql casdoor
    # hopefully enough time for even the slower systems
	sleep 15
	docker compose stop

    # Init finished, remove init mount
    echo '{}' > init_data.json
}

main() {

    docker compose down

    rm -rvf casdoor_files data s3_data

    # copy init_data.json template
    cp -f init_data.json.template init_data.json

    test -f .env || cp env.template .env

    section_regenerate_secrets
    section_regenerate_redirect_uris

    docker compose up -d --remove-orphans

    section_display_configurated_report

}
main
# section_display_configurated_report
