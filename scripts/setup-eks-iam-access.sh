#!/bin/bash

# 대기 시도 횟수 제한
MAX_RETRIES=5
RETRY_INTERVAL=10
COUNT=0

echo "Checking EKS cluster status for '${CLUSTER_NAME}' in region '${REGION}'..."

while [ $COUNT -lt $MAX_RETRIES ]; do
  STATUS=$(aws eks describe-cluster \
    --region "${REGION}" \
    --name "${CLUSTER_NAME}" \
    --query "cluster.status" \
    --output text 2>/dev/null)

  echo "[$COUNT] Cluster status: ${STATUS}"

  if [ "$STATUS" = "ACTIVE" ]; then
    echo "Cluster is ACTIVE. Proceeding with access entry setup..."
    break
  fi

  COUNT=$((COUNT + 1))
  echo "region ${REGION} Cluster ${CLUSTER_NAME} not ready yet. Waiting for ${RETRY_INTERVAL} seconds..."
  sleep $RETRY_INTERVAL
done

if [ "$STATUS" != "ACTIVE" ]; then
  echo "ERROR: Cluster did not become ACTIVE within ${MAX_RETRIES} retries."
  exit 1
fi

PRINCIPAL_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:user/${USER_NAME}"

# Access Entry 생성
aws eks create-access-entry \
  --region "${REGION}" \
  --cluster-name "${CLUSTER_NAME}" \
  --principal-arn "${PRINCIPAL_ARN}"

# Admin 권한 연결
aws eks associate-access-policy \
  --region "${REGION}" \
  --cluster-name "${CLUSTER_NAME}" \
  --principal-arn "${PRINCIPAL_ARN}" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster

# 보기 권한도 같이 연결 (선택적)
aws eks associate-access-policy \
  --region "${REGION}" \
  --cluster-name "${CLUSTER_NAME}" \
  --principal-arn "${PRINCIPAL_ARN}" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy \
  --access-scope type=cluster

