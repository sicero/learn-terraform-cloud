const AWS = require('aws-sdk');

// Configure AWS SDK
AWS.config.update({
  region: 'your-region', // Replace with your AWS region
});

// Create an instance of the Cognito Identity Provider
const cognitoIdentityServiceProvider = new AWS.CognitoIdentityServiceProvider();

// Lambda handler function
exports.handler = async (event, context) => {
  try {
    // Replace these values with your User Pool details
    const userPoolId = process.env.COGNITO_USER_POOL_ID; // Replace with your User Pool ID
    const clientId =  process.env.COGNITO_USER_POOL_CLIENT_ID; // Replace with your Client ID

    const usersToCreate = [
      {
        Username: 'user1@example.com',
        TemporaryPassword: 'Password123!',
        UserAttributes: [
          { Name: 'email', Value: 'user1@example.com' },
          // Add more user attributes as needed
        ],
      },
      // Add more user objects as needed
    ];

    // Create users in the Cognito User Pool
    for (const user of usersToCreate) {
      await cognitoIdentityServiceProvider
        .adminCreateUser({
          UserPoolId: userPoolId,
          Username: user.Username,
          TemporaryPassword: user.TemporaryPassword,
          UserAttributes: user.UserAttributes,
        })
        .promise();
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Users created successfully' }),
    };
  } catch (error) {
    console.error('Error creating users:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Error creating users' }),
    };
  }
};
