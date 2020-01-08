#!/bin/bash

# Suggested by Github actions to be strict
set -e
set -o pipefail

################################################################################
# Global Variables (we can't use GITHUB_ prefix)
################################################################################

API_VERSION=v3
BASE=https://api.github.com
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
HEADER="Accept: application/vnd.github.${API_VERSION}+json"
HEADER="${HEADER}; application/vnd.github.antiope-preview+json; application/vnd.github.shadow-cat-preview+json"

# URLs
REPO_URL="${BASE}/repos/${GITHUB_REPOSITORY}"
PULLS_URL=$REPO_URL/pulls

################################################################################
# Helper Functions
################################################################################


check_credentials() {

    if [[ -z "${GITHUB_TOKEN}" ]]; then
        echo "You must include the GITHUB_TOKEN as an environment variable."
        exit 1
    fi

}

check_events_json() {

    if [[ ! -f "${GITHUB_EVENT_PATH}" ]]; then
        echo "Cannot find Github events file at ${GITHUB_EVENT_PATH}";
        exit 1;
    fi
    echo "Found ${GITHUB_EVENT_PATH}";

}

create_pull_request() {

    # Expected environment variables to be set upfront
    #SOURCE  # from this branch
    #TARGET  # pull request TO this target
    #BODY    # this is the content of the message
    #TITLE   # pull request title

    # Check if the branch already has a pull request open

    DATA="{\"base\":\"${TARGET}\", \"head\":\"${SOURCE}\", \"body\":\"${BODY}\"}"
    RESPONSE=$(curl -sSL -H "${AUTH_HEADER}" -H "${HEADER}" --user "${GITHUB_ACTOR}" -X GET --data "${DATA}" ${PULLS_URL})
    PR=$(echo "${RESPONSE}" | jq --raw-output '.[] | .head.ref')
    echo "Response ref: ${PR}"

    # Option 1: The pull request is already open
    if [[ "${PR}" == "${SOURCE}" ]]; then
        echo "Pull request from ${SOURCE} to ${TARGET} is already open!"

    # Option 2: Open a new pull request
    else
        # Post the pull request
        DATA="{\"title\":\"${TITLE}\", \"body\":\"${BODY}\", \"base\":\"${TARGET}\", \"head\":\"${SOURCE}\", \"draft\":false}"
        echo "curl --user ${GITHUB_ACTOR} -X POST --data ${DATA} ${PULLS_URL}"
        curl -sSL -H "${AUTH_HEADER}" -H "${HEADER}" --user "${GITHUB_ACTOR}" -X POST --data "${DATA}" ${PULLS_URL}
        echo $?
    fi
}


main () {

    # path to file that contains the POST response of the event
    # Example: https://github.com/actions/bin/tree/master/debug
    # Value: /github/workflow/event.json
    check_events_json;

    # Ensure we have a GitHub token
    check_credentials
    
    create_pull_request
}

echo "==========================================================================
START: Running Pull Request on Branch Update Action!";
main;
echo "==========================================================================
END: Finished";
