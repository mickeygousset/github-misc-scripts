#!/bin/bash

# gets the custom repository roles for all organizations in an enterprise

# need: `gh auth refresh -h github.com -s read:org -s read:enterprise`

# note: format is tsv

if [ $# -lt 1 ]
  then
    echo "usage: $0 <enterprise-slug> <hostname> > output.tsv"
    exit 1
fi

export PAGER=""
enterpriseslug=$1
hostname=$2

# set hostname to github.com by default
if [ -z "$hostname" ]
then
  hostname="github.com"
fi

organizations=$(gh api graphql --paginate --hostname $hostname -f enterpriseName="$enterpriseslug" -f query='
query getEnterpriseOrganizations($enterpriseName: String! $endCursor: String) {
  enterprise(slug: $enterpriseName) {
    organizations(first: 100, after: $endCursor) {
      nodes {
        id
        login
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
}' --jq '.data.enterprise.organizations.nodes[].login')

echo -e "Org\tCustoim Role Count"

for org in $organizations
do
  gh api "orgs/$org/custom-repository-roles" --hostname $hostname --jq ". | [\"$org\", .total_count] | @tsv"
done
