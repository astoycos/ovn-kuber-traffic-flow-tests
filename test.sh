#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


#
# Default values (possible to override)
#
DEBUG_TEST=${DEBUG_TEST:-false}
TEST_CASE=${TEST_CASE:-0}
VERBOSE=${VERBOSE:-false}
SERVER_POD_NAME=${SERVER_POD_NAME:-web-server-node-v4}
SERVER_HOST_POD_NAME=${SERVER_HOST_POD_NAME:-web-server-host-node-v4}
CLIENT_POD_NAME_PREFIX=${CLIENT_POD_NAME_PREFIX:-web-client-pod}
CLIENT_HOST_POD_NAME_PREFIX=${CLIENT_HOST_POD_NAME_PREFIX:-web-client-host}
REMOTE_CLIENT_NODE_DEFAULT=${REMOTE_CLIENT_NODE_DEFAULT:-ovn-worker4}
REMOTE_CLIENT_NODE_BACKUP=${REMOTE_CLIENT_NODE_BACKUP:-ovn-worker5}
NODEPORT_SVC_NAME=${NODEPORT_SVC_NAME:-my-web-service-node-v4}
NODEPORT_HOST_SVC_NAME=${NODEPORT_HOST_SVC_NAME:-my-web-service-host-node-v4}
NODEPORT_POD_PORT=${NODEPORT_POD_PORT:-30080}
NODEPORT_HOST_PORT=${NODEPORT_HOST_PORT:-30180}
POD_SERVER_STRING=${POD_SERVER_STRING:-"Server - Pod Backend Reached"}
HOST_SERVER_STRING=${HOST_SERVER_STRING:-"Server - Host Backend Reached"}
EXTERNAL_SERVER_STRING=${EXTERNAL_SERVER_STRING:-"The document has moved"}
EXTERNAL_IP=${EXTERNAL_IP:-8.8.8.8}
EXTERNAL_URL=${EXTERNAL_URL:-google.com}

#
# Query for dynamic data
#
SERVER_NODE=`kubectl get pods -o wide | grep $SERVER_POD_NAME  | awk -F' ' '{print $7}'`
SERVER_IP=`kubectl get pods -o wide | grep $SERVER_POD_NAME  | awk -F' ' '{print $6}'`

LOCAL_CLIENT_NODE=$SERVER_NODE
LOCAL_CLIENT_POD=`kubectl get pods -o wide | grep $CLIENT_POD_NAME_PREFIX | grep $LOCAL_CLIENT_NODE | awk -F' ' '{print $1}'`

REMOTE_CLIENT_NODE=$REMOTE_CLIENT_NODE_DEFAULT
if [ "$SERVER_NODE" == "$REMOTE_CLIENT_NODE_DEFAULT" ]; then
  REMOTE_CLIENT_NODE=$REMOTE_CLIENT_NODE_BACKUP
fi
REMOTE_CLIENT_POD=`kubectl get pods -o wide | grep $CLIENT_POD_NAME_PREFIX | grep $REMOTE_CLIENT_NODE | awk -F' ' '{print $1}'`

NODEPORT_CLUSTER_IPV4=`kubectl get services | grep $NODEPORT_SVC_NAME | awk -F' ' '{print $3}'`
#NODEPORT_EXTERNAL_IPV4=`kubectl get endpoints | grep $NODEPORT_SVC_NAME | awk -F' ' '{print $2}'`
NODEPORT_EXTERNAL_IPV4=$SERVER_IP

SERVER_HOST_NODE=`kubectl get pods -o wide | grep $SERVER_HOST_POD_NAME  | awk -F' ' '{print $7}'`
SERVER_HOST_IP=`kubectl get pods -o wide | grep $SERVER_HOST_POD_NAME  | awk -F' ' '{print $6}'`

REMOTE_CLIENT_HOST_NODE=$REMOTE_CLIENT_NODE_DEFAULT
if [ "$SERVER_HOST_NODE" == "$REMOTE_CLIENT_NODE_DEFAULT" ]; then
  REMOTE_CLIENT_HOST_NODE=$REMOTE_CLIENT_NODE_BACKUP
fi
LOCAL_CLIENT_HOST_POD=`kubectl get pods -o wide | grep $CLIENT_POD_NAME_PREFIX | grep $SERVER_HOST_NODE | awk -F' ' '{print $1}'`
REMOTE_CLIENT_HOST_POD=`kubectl get pods -o wide | grep $CLIENT_POD_NAME_PREFIX | grep $REMOTE_CLIENT_HOST_NODE | awk -F' ' '{print $1}'`

NODEPORT_HOST_CLUSTER_IPV4=`kubectl get services | grep $NODEPORT_HOST_SVC_NAME | awk -F' ' '{print $3}'`
#NODEPORT_HOST_EXTERNAL_IPV4=`kubectl get endpoints | grep $NODEPORT_HOST_SVC_NAME | awk -F' ' '{print $2}'`
NODEPORT_HOST_EXTERNAL_IPV4=$SERVER_HOST_IP


# NOTE: env in the container has values that could be used instead of using the above commands:
#
# kubectl exec -it $LOCAL_CLIENT_POD -- env
#  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#  HOSTNAME=web-client-w2rps
#  container=docker
#  MY_WEB_SERVICE_NODE_V4_SERVICE_PORT=80
#  MY_WEB_SERVICE_NODE_V4_PORT_80_TCP_PORT=80
#  KUBERNETES_PORT_443_TCP_PROTO=tcp
#  MY_WEB_SERVICE_NODE_V4_SERVICE_HOST=10.96.66.203
#  MY_WEB_SERVICE_NODE_V4_PORT=tcp://10.96.66.203:80
#  MY_WEB_SERVICE_NODE_V4_PORT_80_TCP=tcp://10.96.66.203:80
#  KUBERNETES_SERVICE_HOST=10.96.0.1
#  MY_WEB_SERVICE_NODE_V4_PORT_80_TCP_PROTO=tcp
#  KUBERNETES_SERVICE_PORT_HTTPS=443
#  KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
#  KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
#  MY_WEB_SERVICE_NODE_V4_SERVICE_PORT_WEBSERVER_NODE_V4_80=80
#  MY_WEB_SERVICE_NODE_V4_PORT_80_TCP_ADDR=10.96.66.203
#  KUBERNETES_SERVICE_PORT=443
#  KUBERNETES_PORT=tcp://10.96.0.1:443
#  KUBERNETES_PORT_443_TCP_PORT=443
#
# kubectl exec -it $LOCAL_CLIENT_POD -- /bin/sh -c 'curl "http://$MY_WEB_SERVICE_NODE_V4_SERVICE_HOST:$MY_WEB_SERVICE_NODE_V4_SERVICE_PORT/"'


#
# Dump working data
#
echo
echo "Default/Override Values:"
echo "  DEBUG_TEST                   $DEBUG_TEST"
echo "  TEST_CASE (0 means all)      $TEST_CASE"
echo "  VERBOSE                      $VERBOSE"
echo "  SERVER_POD_NAME              $SERVER_POD_NAME"
echo "  SERVER_HOST_POD_NAME         $SERVER_HOST_POD_NAME"
echo "  CLIENT_POD_NAME_PREFIX       $CLIENT_POD_NAME_PREFIX"
echo "  REMOTE_CLIENT_NODE_DEFAULT   $REMOTE_CLIENT_NODE_DEFAULT"
echo "  REMOTE_CLIENT_NODE_BACKUP    $REMOTE_CLIENT_NODE_BACKUP"
echo "  NODEPORT_SVC_NAME            $NODEPORT_SVC_NAME"
echo "  NODEPORT_HOST_SVC_NAME       $NODEPORT_HOST_SVC_NAME"
echo "  NODEPORT_POD_PORT            $NODEPORT_POD_PORT"
echo "  NODEPORT_HOST_PORT           $NODEPORT_HOST_PORT"
echo "  POD_SERVER_STRING            $POD_SERVER_STRING"
echo "  HOST_SERVER_STRING           $HOST_SERVER_STRING"
echo "  EXTERNAL_SERVER_STRING       $EXTERNAL_SERVER_STRING"
echo "  EXTERNAL_IP                  $EXTERNAL_IP"
echo "  EXTERNAL_URL                 $EXTERNAL_URL"
echo "Queried Values:"
echo " Pod Backed:"
echo "  SERVER_IP                    $SERVER_IP"
echo "  SERVER_NODE                  $SERVER_NODE"
echo "  LOCAL_CLIENT_NODE            $LOCAL_CLIENT_NODE"
echo "  LOCAL_CLIENT_POD             $LOCAL_CLIENT_POD"
echo "  REMOTE_CLIENT_NODE           $REMOTE_CLIENT_NODE"
echo "  REMOTE_CLIENT_POD            $REMOTE_CLIENT_POD"
echo "  NODEPORT_CLUSTER_IPV4        $NODEPORT_CLUSTER_IPV4"
echo "  NODEPORT_EXTERNAL_IPV4       $NODEPORT_EXTERNAL_IPV4"
echo " Host backed:"
echo "  SERVER_HOST_IP               $SERVER_HOST_IP"
echo "  SERVER_HOST_NODE             $SERVER_HOST_NODE"
echo "  REMOTE_CLIENT_HOST_NODE      $REMOTE_CLIENT_HOST_NODE"
echo "  LOCAL_CLIENT_HOST_POD        $LOCAL_CLIENT_HOST_POD"
echo "  REMOTE_CLIENT_HOST_POD       $REMOTE_CLIENT_HOST_POD"
echo "  NODEPORT_HOST_CLUSTER_IPV4   $NODEPORT_HOST_CLUSTER_IPV4"
echo "  NODEPORT_HOST_EXTERNAL_IPV4  $NODEPORT_HOST_EXTERNAL_IPV4"
echo


process-curl-output() {
   if [ "$VERBOSE" == true ]; then
      echo "${1}"
   fi
   echo "${1}" | grep -cq "${2}" && echo -e "${GREEN}SUCCESS${NC}\r\n" || echo -e "${RED}FAILED${NC}\r\n"
}


#
# Test each scenario
#
if [ "$TEST_CASE" == 0 ] || [ "$TEST_CASE" == 1 ]; then
  echo
  echo "FLOW 01: Typical Pod to Pod traffic (using cluster subnet)"
  echo "----------------------------------------------------------"
  echo
  echo "*** Pod to Pod (Same Node) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "kubectl exec -it $LOCAL_CLIENT_POD -- ping $SERVER_IP -c 3"
    kubectl exec -it $LOCAL_CLIENT_POD -- ping $SERVER_IP -c 3
    echo
  fi
  echo "kubectl exec -it $LOCAL_CLIENT_POD -- curl \"http://$SERVER_IP:80/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_POD -- curl "http://$SERVER_IP:80/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo

  echo
  echo "*** Pod to Pod (Different Node) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "kubectl exec -it $REMOTE_CLIENT_POD -- ping $SERVER_IP -c 3"
    kubectl exec -it $REMOTE_CLIENT_POD -- ping $SERVER_IP -c 3
    echo
  fi
  echo "kubectl exec -it $REMOTE_CLIENT_POD -- curl \"http://$SERVER_IP:80/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_POD -- curl "http://$SERVER_IP:80/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo
fi


if [ "$TEST_CASE" == 0 ] || [ "$TEST_CASE" == 2 ]; then
  echo
  echo "FLOW 02: Pod -> Cluster IP Service traffic"
  echo "------------------------------------------"
  echo
  echo "*** Pod -> Cluster IP Service traffic (Same Node) ***"
  #if [ "$DEBUG_TEST" == true ]; then
  #  echo "kubectl exec -it $LOCAL_CLIENT_POD -- ping $NODEPORT_CLUSTER_IPV4 -c 3"
  #  kubectl exec -it $LOCAL_CLIENT_POD -- ping $NODEPORT_CLUSTER_IPV4 -c 3
  #  echo
  #fi
  echo "kubectl exec -it $LOCAL_CLIENT_POD -- curl \"http://$NODEPORT_CLUSTER_IPV4:80/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_POD -- curl "http://$NODEPORT_CLUSTER_IPV4:80/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo

  echo
  echo "*** Pod -> Cluster IP Service traffic (Different Node) ***"
  #if [ "$DEBUG_TEST" == true ]; then
  #  echo "kubectl exec -it $REMOTE_CLIENT_POD -- ping $NODEPORT_CLUSTER_IPV4 -c 3"
  #  kubectl exec -it $REMOTE_CLIENT_POD -- ping $NODEPORT_CLUSTER_IPV4 -c 3
  #  echo
  #fi
  echo "kubectl exec -it $REMOTE_CLIENT_POD -- curl \"http://$NODEPORT_CLUSTER_IPV4:80/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_POD -- curl "http://$NODEPORT_CLUSTER_IPV4:80/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo
fi


if [ "$TEST_CASE" == 0 ] || [ "$TEST_CASE" == 3 ]; then
  echo
  echo "FLOW 03: Pod -> NodePort Service traffic (pod/host backend)"
  echo "-----------------------------------------------------------"
  echo
  echo "*** Pod -> NodePort Service traffic (pod backend - Same Node) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "kubectl exec -it $LOCAL_CLIENT_POD -- ping $NODEPORT_EXTERNAL_IPV4 -c 3"
    kubectl exec -it $LOCAL_CLIENT_POD -- ping $NODEPORT_EXTERNAL_IPV4 -c 3
    echo
    echo "kubectl exec -it $LOCAL_CLIENT_POD -- curl \"http://$NODEPORT_EXTERNAL_IPV4:80/index.html\""
    TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_POD -- curl "http://$NODEPORT_EXTERNAL_IPV4:80/index.html"`
    process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
    echo "kubectl exec -it $LOCAL_CLIENT_POD -- curl \"http://$NODEPORT_SVC_NAME:80/\""
    TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_POD -- curl "http://$NODEPORT_SVC_NAME:80/"`
    process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
    echo
  fi
  echo -e "${BLUE}ERROR - NAME:30080 works but IP:30080 doesn't${NC}"
  #kubectl exec -it web-client-pod-v2xgq -- curl "http://10.244.0.9:30080/"
  #command terminated with exit code 7
  #curl: (7) Failed connect to 10.244.0.9:30080; Connection refused
  echo "kubectl exec -it $LOCAL_CLIENT_POD -- curl \"http://$NODEPORT_EXTERNAL_IPV4:$NODEPORT_POD_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_POD -- curl "http://$NODEPORT_EXTERNAL_IPV4:$NODEPORT_POD_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo "kubectl exec -it $LOCAL_CLIENT_POD -- curl \"http://$NODEPORT_SVC_NAME:$NODEPORT_POD_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_POD -- curl "http://$NODEPORT_SVC_NAME:$NODEPORT_POD_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo

  echo
  echo "*** Pod -> NodePort Service traffic (pod backend - Different Node) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "kubectl exec -it $REMOTE_CLIENT_POD -- ping $NODEPORT_EXTERNAL_IPV4 -c 3"
    kubectl exec -it $REMOTE_CLIENT_POD -- ping $NODEPORT_EXTERNAL_IPV4 -c 3
    echo
    echo "kubectl exec -it $REMOTE_CLIENT_POD -- curl \"http://$NODEPORT_EXTERNAL_IPV4:80/\""
    TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_POD -- curl "http://$NODEPORT_EXTERNAL_IPV4:80/"`
    process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
    echo "kubectl exec -it $REMOTE_CLIENT_POD -- curl \"http://$NODEPORT_SVC_NAME:80/\""
    TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_POD -- curl "http://$NODEPORT_SVC_NAME:80/"`
    process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
    echo
  fi
  echo -e "${BLUE}ERROR - NAME:30080 works but IP:30080 doesn't${NC}"
  #kubectl exec -it web-client-pod-7crrr -- curl "http://10.244.0.9:30080/"
  #command terminated with exit code 7
  #curl: (7) Failed connect to 10.244.0.9:30080; Connection refused
  echo "kubectl exec -it $REMOTE_CLIENT_POD -- curl \"http://$NODEPORT_EXTERNAL_IPV4:$NODEPORT_POD_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_POD -- curl "http://$NODEPORT_EXTERNAL_IPV4:$NODEPORT_POD_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo "kubectl exec -it $REMOTE_CLIENT_POD -- curl \"http://$NODEPORT_SVC_NAME:$NODEPORT_POD_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_POD -- curl "http://$NODEPORT_SVC_NAME:$NODEPORT_POD_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo

  echo
  echo "*** Pod -> NodePort Service traffic (host networked pod backend - Same Node) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "kubectl exec -it $LOCAL_CLIENT_POD -- ping $NODEPORT_HOST_EXTERNAL_IPV4 -c 3"
    kubectl exec -it $LOCAL_CLIENT_POD -- ping $NODEPORT_HOST_EXTERNAL_IPV4 -c 3
    echo
    echo "kubectl exec -it $LOCAL_CLIENT_POD -- curl \"http://$NODEPORT_HOST_EXTERNAL_IPV4:80/\""
    TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_POD -- curl "http://$NODEPORT_HOST_EXTERNAL_IPV4:80/"`
    process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
    echo "kubectl exec -it $LOCAL_CLIENT_POD -- curl \"http://$NODEPORT_HOST_SVC_NAME:80/\""
    TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_POD -- curl "http://$NODEPORT_HOST_SVC_NAME:80/"`
    process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
    echo
  fi
  echo "kubectl exec -it $LOCAL_CLIENT_POD -- curl \"http://$NODEPORT_HOST_EXTERNAL_IPV4:$NODEPORT_HOST_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_POD -- curl "http://$NODEPORT_HOST_EXTERNAL_IPV4:$NODEPORT_HOST_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  echo "kubectl exec -it $LOCAL_CLIENT_POD -- curl \"http://$NODEPORT_HOST_SVC_NAME:$NODEPORT_HOST_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_POD -- curl "http://$NODEPORT_HOST_SVC_NAME:$NODEPORT_HOST_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  echo

  echo
  echo "*** Pod -> NodePort Service traffic (host networked pod backend - Different Node) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "kubectl exec -it $REMOTE_CLIENT_POD -- ping $NODEPORT_HOST_EXTERNAL_IPV4 -c 3"
    kubectl exec -it $REMOTE_CLIENT_POD -- ping $NODEPORT_HOST_EXTERNAL_IPV4 -c 3
    echo
    echo "kubectl exec -it $REMOTE_CLIENT_POD -- curl \"http://$NODEPORT_HOST_EXTERNAL_IPV4:80/\""
    TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_POD -- curl "http://$NODEPORT_HOST_EXTERNAL_IPV4:80/"`
    process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
    echo "kubectl exec -it $REMOTE_CLIENT_POD -- curl \"http://$NODEPORT_HOST_SVC_NAME:80/\""
    TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_POD -- curl "http://$NODEPORT_HOST_SVC_NAME:80/"`
    process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
    echo
  fi
  echo "kubectl exec -it $REMOTE_CLIENT_POD -- curl \"http://$NODEPORT_HOST_EXTERNAL_IPV4:$NODEPORT_HOST_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_POD -- curl "http://$NODEPORT_HOST_EXTERNAL_IPV4:$NODEPORT_HOST_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  echo "kubectl exec -it $REMOTE_CLIENT_POD -- curl \"http://$NODEPORT_HOST_SVC_NAME:$NODEPORT_HOST_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_POD -- curl "http://$NODEPORT_HOST_SVC_NAME:$NODEPORT_HOST_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  echo
fi


if [ "$TEST_CASE" == 0 ] || [ "$TEST_CASE" == 4 ]; then
  echo
  echo "FLOW 04: Pod -> External Network (egress traffic)"
  echo "-------------------------------------------------"
  echo
  echo "*** Pod -> External Network (egress traffic) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "kubectl exec -it $REMOTE_CLIENT_POD -- ping $EXTERNAL_IP -c 3"
    kubectl exec -it $REMOTE_CLIENT_POD -- ping $EXTERNAL_IP -c 3
    echo
  fi
  echo "kubectl exec -it $REMOTE_CLIENT_POD -- curl $EXTERNAL_URL"
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_POD -- curl $EXTERNAL_URL`
  process-curl-output "${TMP_OUTPUT}" "${EXTERNAL_SERVER_STRING}"
  echo
fi


if [ "$TEST_CASE" == 0 ] || [ "$TEST_CASE" == 5 ]; then
  echo
  echo "FLOW 05: Host -> Cluster IP Service traffic (pod backend)"
  echo "---------------------------------------------------------"
  echo
  echo "*** Host -> Cluster IP Service traffic (pod backend - Same Node) ***"
  #if [ "$DEBUG_TEST" == true ]; then
  #  echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- ping $NODEPORT_CLUSTER_IPV4 -c 3"
  #  kubectl exec -it $LOCAL_CLIENT_HOST_POD -- ping $NODEPORT_CLUSTER_IPV4 -c 3
  #  echo
  #fi
  echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl \"http://$NODEPORT_CLUSTER_IPV4:80/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl "http://$NODEPORT_CLUSTER_IPV4:80/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo

  echo
  echo "*** Host -> Cluster IP Service traffic (pod backend - Different Node) ***"
  #if [ "$DEBUG_TEST" == true ]; then
  #  echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- ping $NODEPORT_CLUSTER_IPV4 -c 3"
  #  kubectl exec -it $REMOTE_CLIENT_HOST_POD -- ping $NODEPORT_CLUSTER_IPV4 -c 3
  #  echo
  #fi
  echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl \"http://$NODEPORT_CLUSTER_IPV4:80/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl "http://$NODEPORT_CLUSTER_IPV4:80/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo
fi


if [ "$TEST_CASE" == 0 ] || [ "$TEST_CASE" == 6 ]; then
  echo
  echo "FLOW 06: Host -> NodePort Service traffic (pod backend)"
  echo "-------------------------------------------------------"
  echo
  echo "*** Host -> NodePort Service traffic (pod backend - Same Node) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- ping $NODEPORT_EXTERNAL_IPV4 -c 3"
    kubectl exec -it $LOCAL_CLIENT_HOST_POD -- ping $NODEPORT_EXTERNAL_IPV4 -c 3
    echo
    echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl \"http://$NODEPORT_EXTERNAL_IPV4:80/\""
    TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl "http://$NODEPORT_EXTERNAL_IPV4:80/"`
    process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
    echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl \"http://$NODEPORT_SVC_NAME:80/\""
    TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl "http://$NODEPORT_SVC_NAME:80/"`
    process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
    echo
  fi
  echo -e "${BLUE}ERROR - NAME:30080 works but IP:30080 doesn't${NC}"
  #kubectl exec -it web-client-pod-s72ds -- curl "http://10.244.1.4:30080/"
  #curl: (7) Failed connect to 10.244.1.4:30080; Connection refused
  #command terminated with exit code 7
  echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl \"http://$NODEPORT_EXTERNAL_IPV4:$NODEPORT_POD_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl "http://$NODEPORT_EXTERNAL_IPV4:$NODEPORT_POD_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl \"http://$NODEPORT_SVC_NAME:$NODEPORT_POD_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl "http://$NODEPORT_SVC_NAME:$NODEPORT_POD_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo

  echo
  echo "*** Host -> NodePort Service traffic (pod backend - Different Node) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- ping $NODEPORT_EXTERNAL_IPV4 -c 3"
    kubectl exec -it $REMOTE_CLIENT_HOST_POD -- ping $NODEPORT_EXTERNAL_IPV4 -c 3
    echo
    echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl \"http://$NODEPORT_EXTERNAL_IPV4:80/\""
    TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl "http://$NODEPORT_EXTERNAL_IPV4:80/"`
    process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
    echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl \"http://$NODEPORT_SVC_NAME:80/\""
    TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl "http://$NODEPORT_SVC_NAME:80/"`
    process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
    echo
  fi
  echo -e "${BLUE}ERROR - NAME:30080 works but IP:30080 doesn't${NC}"
  #kubectl exec -it web-client-pod-7crrr -- curl "http://10.244.1.4:30080/"
  #curl: (7) Failed connect to 10.244.1.4:30080; Connection refused
  #command terminated with exit code 7
  echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl \"http://$NODEPORT_EXTERNAL_IPV4:$NODEPORT_POD_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl "http://$NODEPORT_EXTERNAL_IPV4:$NODEPORT_POD_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl \"http://$NODEPORT_SVC_NAME:$NODEPORT_POD_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl "http://$NODEPORT_SVC_NAME:$NODEPORT_POD_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  echo
fi


if [ "$TEST_CASE" == 0 ] || [ "$TEST_CASE" == 7 ]; then
  echo
  echo "FLOW 07: Host -> Cluster IP Service traffic (host networked pod backend)"
  echo "------------------------------------------------------------------------"
  echo
  echo "*** Host -> Cluster IP Service traffic (host networked pod backend - Same Node) ***"
  #if [ "$DEBUG_TEST" == true ]; then
  #  echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- ping $NODEPORT_HOST_CLUSTER_IPV4 -c 3"
  #  kubectl exec -it $LOCAL_CLIENT_HOST_POD -- ping $NODEPORT_HOST_CLUSTER_IPV4 -c 3
  #  echo
  #fi
  echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl \"http://$NODEPORT_HOST_CLUSTER_IPV4:80/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl "http://$NODEPORT_HOST_CLUSTER_IPV4:80/"`
  process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  echo

  echo
  echo "*** Host -> Cluster IP Service traffic (host networked pod backend - Different Node) ***"
  #if [ "$DEBUG_TEST" == true ]; then
  #  echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- ping $NODEPORT_HOST_CLUSTER_IPV4 -c 3"
  #  kubectl exec -it $REMOTE_CLIENT_HOST_POD -- ping $NODEPORT_HOST_CLUSTER_IPV4 -c 3
  #  echo
  #fi
  echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl \"http://$NODEPORT_HOST_CLUSTER_IPV4:80/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl "http://$NODEPORT_HOST_CLUSTER_IPV4:80/"`
  process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  echo
fi


if [ "$TEST_CASE" == 0 ] || [ "$TEST_CASE" == 8 ]; then
  echo
  echo "FLOW 08: Host -> NodePort Service traffic (host networked pod backend)"
  echo "----------------------------------------------------------------------"
  echo
  echo "*** Host -> NodePort Service traffic (host networked pod backend - Same Node) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- ping $NODEPORT_HOST_EXTERNAL_IPV4 -c 3"
    kubectl exec -it $LOCAL_CLIENT_HOST_POD -- ping $NODEPORT_HOST_EXTERNAL_IPV4 -c 3
    echo
    echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl \"http://$NODEPORT_HOST_EXTERNAL_IPV4:80/\""
    TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl "http://$NODEPORT_HOST_EXTERNAL_IPV4:80/"`
    process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
    echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl \"http://$NODEPORT_HOST_SVC_NAME:80/\""
    TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl "http://$NODEPORT_HOST_SVC_NAME:80/"`
    process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
    echo
  fi
  echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl \"http://$NODEPORT_HOST_EXTERNAL_IPV4:$NODEPORT_HOST_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl "http://$NODEPORT_HOST_EXTERNAL_IPV4:$NODEPORT_HOST_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  echo "kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl \"http://$NODEPORT_HOST_SVC_NAME:$NODEPORT_HOST_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $LOCAL_CLIENT_HOST_POD -- curl "http://$NODEPORT_HOST_SVC_NAME:$NODEPORT_HOST_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  echo

  echo
  echo "*** Host -> NodePort Service traffic (host networked pod backend - Different Node) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- ping $NODEPORT_HOST_EXTERNAL_IPV4 -c 3"
    kubectl exec -it $REMOTE_CLIENT_HOST_POD -- ping $NODEPORT_HOST_EXTERNAL_IPV4 -c 3
    echo
    echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl \"http://$NODEPORT_HOST_EXTERNAL_IPV4:80/\""
    TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl "http://$NODEPORT_HOST_EXTERNAL_IPV4:80/"`
    process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
    echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl \"http://$NODEPORT_HOST_SVC_NAME:80/\""
    TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl "http://$NODEPORT_HOST_SVC_NAME:80/"`
    process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
    echo
  fi
  echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl \"http://$NODEPORT_HOST_EXTERNAL_IPV4:$NODEPORT_HOST_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl "http://$NODEPORT_HOST_EXTERNAL_IPV4:$NODEPORT_HOST_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  echo "kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl \"http://$NODEPORT_HOST_SVC_NAME:$NODEPORT_HOST_PORT/\""
  TMP_OUTPUT=`kubectl exec -it $REMOTE_CLIENT_HOST_POD -- curl "http://$NODEPORT_HOST_SVC_NAME:$NODEPORT_HOST_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  echo
fi


if [ "$TEST_CASE" == 0 ] || [ "$TEST_CASE" == 9 ]; then
  echo
  echo "FLOW 09: External Network Traffic -> NodePort/External IP Service (ingress traffic)"
  echo "-----------------------------------------------------------------------------------"
  echo
  echo "*** External Network Traffic -> NodePort/External IP Service (ingress traffic - pod backend) ***"
  #if [ "$DEBUG_TEST" == true ]; then
  #  echo "ping $NODEPORT_EXTERNAL_IPV4 -c 3"
  #  ping $NODEPORT_EXTERNAL_IPV4 -c 3
  #  echo
  #  echo "curl \"http://$NODEPORT_EXTERNAL_IPV4:80/\""
  #  TMP_OUTPUT=`curl "http://$NODEPORT_EXTERNAL_IPV4:80/"`
  #  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  #  echo "curl \"http://$NODEPORT_SVC_NAME:80/\""
  #  TMP_OUTPUT=`curl "http://$NODEPORT_SVC_NAME:80/"`
  #  process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  #  echo
  #fi
  echo "curl \"http://$NODEPORT_EXTERNAL_IPV4:$NODEPORT_POD_PORT/\""
  echo -e "${BLUE}NOT WORKING${NC}"
  #TMP_OUTPUT=`curl "http://$NODEPORT_EXTERNAL_IPV4:$NODEPORT_POD_PORT/"`
  #process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  #echo "curl \"http://$NODEPORT_SVC_NAME:$NODEPORT_POD_PORT/\""
  #TMP_OUTPUT=`curl "http://$NODEPORT_SVC_NAME:$NODEPORT_POD_PORT/"`
  #process-curl-output "${TMP_OUTPUT}" "${POD_SERVER_STRING}"
  #echo

  echo
  echo "*** External Network Traffic -> NodePort/External IP Service (ingress traffic - host backend) ***"
  if [ "$DEBUG_TEST" == true ]; then
    echo "ping $NODEPORT_HOST_EXTERNAL_IPV4 -c 3"
    ping $NODEPORT_HOST_EXTERNAL_IPV4 -c 3
    echo
    #echo "curl \"http://$NODEPORT_HOST_EXTERNAL_IPV4:80/\""
    #TMP_OUTPUT=`curl "http://$NODEPORT_HOST_EXTERNAL_IPV4:80/"`
    #process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
    #echo "curl \"http://$NODEPORT_HOST_SVC_NAME:80/\""
    #TMP_OUTPUT=`curl "http://$NODEPORT_HOST_SVC_NAME:80/"`
    #process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
    #echo
  fi
  echo "curl \"http://$NODEPORT_HOST_EXTERNAL_IPV4:$NODEPORT_HOST_PORT/\""
  TMP_OUTPUT=`curl "http://$NODEPORT_HOST_EXTERNAL_IPV4:$NODEPORT_HOST_PORT/"`
  process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  #echo "curl \"http://$NODEPORT_HOST_SVC_NAME:$NODEPORT_HOST_PORT/\""
  #TMP_OUTPUT=`curl "http://$NODEPORT_HOST_SVC_NAME:$NODEPORT_HOST_PORT/"`
  #process-curl-output "${TMP_OUTPUT}" "${HOST_SERVER_STRING}"
  #echo
fi


if [ "$TEST_CASE" == 0 ] || [ "$TEST_CASE" == 10 ]; then
  echo
  echo "FLOW 10: External network traffic -> pods (multiple external gw traffic)"
  echo "------------------------------------------------------------------------"
  echo -e "${BLUE}NOT IMPLEMENTED${NC}"
  echo
fi

