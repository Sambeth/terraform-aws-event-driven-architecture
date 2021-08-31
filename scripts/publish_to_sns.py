import inspect
from botocore import exceptions
from dataclasses import dataclass
import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


sns = boto3.client(
    "sns"
)


@dataclass
class GatewayResponseHandler:
    """Handle lambda function responses"""
    status_code: int
    body: str
    headers = {
        'Access-Control-Allow-Origin': '*'
    }

    def respond(self):
        return {
            "statusCode": self.status_code,
            "body": json.dumps({
                'status': self.status_code,
                'message': self.body
            }),
            "headers": self.headers
        }


def publish_message(sns_topic, payload, message_group_id_name, subject_type, subject):
    """
    Publishes a message to a topic

    :param sns_topic: (str) Topic to publish to
    :param payload: (str) Message to be published
    :param message_group_id_name: (str) Dict key in payload with unique value (ex: id)
    :param subject_type: (str) The name of the type of payload to be used in filtering
    :param subject: (str) The type of payload (eg. is it PRODUCTS, ORDERS)
    :return response: (dict)
        Response sample:
        {
            'MessageId': '84ccd40f-0267-5fa0-8d43-8d90f6ead098',
            'SequenceNumber': '10000000000000004000',
            'ResponseMetadata': {
                'RequestId': '269c4492-e217-578d-91da-1d0d16c98be2',
                'HTTPStatusCode': 200,
                'HTTPHeaders': {
                    'x-amzn-requestid': '269c4492-e217-578d-91da-1d0d16c98be2',
                    'content-type': 'text/xml',
                    'content-length': '352',
                    'date': 'Wed, 25 Aug 2021 07:34:54 GMT'
                },
                'RetryAttempts': 0}
        }
    """
    subject = subject.upper()

    try:
        response = sns.publish(
            TopicArn=sns_topic,
            Subject=subject,
            Message=payload,
            MessageAttributes={
                subject_type: {
                    "DataType": "String",
                    "StringValue": subject
                }
            },
            MessageGroupId=json.loads(payload)[message_group_id_name]
        )
        logger.info(response)
        return response

    except exceptions.ClientError as error:
        if error.response['Error']['Code'] == 'KMSNotFoundException':
            logger.info('KMS key not found!')
            return GatewayResponseHandler(body='KMS key not found!', status_code=400).respond()
        elif error.response['Error']['Code'] == 'AuthorizationErrorException':
            logger.info('You are not authorized to publish to this topic!')
            return GatewayResponseHandler(
                body='You are not authorized to publish to this topic!', status_code=400).respond()
        else:
            logger.info(error)
            return GatewayResponseHandler(
                body=str(error), status_code=400
            ).respond()


def handler(event, context):
    """
    Sample event payload:
    {
       "resource":"/publish",
       "path":"/publish",
       "httpMethod":"POST",
       "headers":{
          "Accept":"*/*",
          "Accept-Encoding":"gzip, deflate, br",
          "Host":"sxujwcx6v4.execute-api.us-east-2.amazonaws.com",
          "Postman-Token":"0fdd1e0a-e0d5-4379-b9ab-c3a9ce77c022",
          "User-Agent":"PostmanRuntime/7.28.4",
          "X-Amzn-Trace-Id":"Root=1-612bf28d-3f99eac813bc0e2131b5b405",
          "X-Forwarded-For":"34.89.120.52",
          "X-Forwarded-Port":"443",
          "X-Forwarded-Proto":"https"
       },
       "multiValueHeaders":{
          "Accept":[
             "*/*"
          ],
          "Accept-Encoding":[
             "gzip, deflate, br"
          ],
          "Host":[
             "sxujwcx6v4.execute-api.us-east-2.amazonaws.com"
          ],
          "Postman-Token":[
             "0fdd1e0a-e0d5-4379-b9ab-c3a9ce77c022"
          ],
          "User-Agent":[
             "PostmanRuntime/7.28.4"
          ],
          "X-Amzn-Trace-Id":[
             "Root=1-612bf28d-3f99eac813bc0e2131b5b405"
          ],
          "X-Forwarded-For":[
             "34.89.120.52"
          ],
          "X-Forwarded-Port":[
             "443"
          ],
          "X-Forwarded-Proto":[
             "https"
          ]
       },
       "queryStringParameters":{
          "first_name":"retard",
          "last_name":"slim"
       },
       "multiValueQueryStringParameters":{
          "first_name":[
             "retard"
          ],
          "last_name":[
             "slim"
          ]
       },
       "pathParameters":"None",
       "stageVariables":"None",
       "requestContext":{
          "resourceId":"d7712c",
          "resourcePath":"/publish",
          "httpMethod":"POST",
          "extendedRequestId":"E2LWFF9yCYcFZJQ=",
          "requestTime":"29/Aug/2021:20:48:13 +0000",
          "path":"/dev/publish",
          "accountId":"563686632182",
          "protocol":"HTTP/1.1",
          "stage":"dev",
          "domainPrefix":"sxujwcx6v4",
          "requestTimeEpoch":1630270093186,
          "requestId":"d6df4127-baa1-4bed-873f-e9ae01406758",
          "identity":{
             "cognitoIdentityPoolId":"None",
             "accountId":"None",
             "cognitoIdentityId":"None",
             "caller":"None",
             "sourceIp":"34.89.120.52",
             "principalOrgId":"None",
             "accessKey":"None",
             "cognitoAuthenticationType":"None",
             "cognitoAuthenticationProvider":"None",
             "userArn":"None",
             "userAgent":"PostmanRuntime/7.28.4",
             "user":"None"
          },
          "domainName":"sxujwcx6v4.execute-api.us-east-2.amazonaws.com",
          "apiId":"sxujwcx6v4"
       },
       "body":"None",
       "isBase64Encoded":false
    }

    :param event:
    :param context:
    :return:
    """
    logger.info("#### EVENT  ####")
    logger.info(event)

    if event['queryStringParameters']:
        func_parameters = list(inspect.signature(publish_message).parameters.keys())
        try:
            sns_topic = event['queryStringParameters']["sns_topic"]
            payload = event["body"]
            message_group_id = event['queryStringParameters']["message_group_id"]
            subject_type = event['queryStringParameters']["subject_type"]
            subject = event['queryStringParameters']["subject"]
        except KeyError as error:
            return GatewayResponseHandler(
                body=f"Make sure you have set the following query parameters: {func_parameters}", status_code=400
            ).respond()

    else:
        return GatewayResponseHandler(
            body="No query string parameters found! Please add query parameters to endpoint", status_code=400
        ).respond()

    response = publish_message(
        sns_topic=sns_topic,
        payload=payload,
        message_group_id_name=message_group_id,
        subject_type=subject_type,
        subject=subject
    )

    return response
    # return response

    # response = publish_message(
    #     sns_topic='arn:aws:sns:us-east-2:563686632182:mpharma-bloom-products-topic.fifo',
    #     payload=payload,
    #     message_group_id='product_id',
    #     subject_type='ProductType',
    #     subject='BLOOMPRODUCTS'
    # )
