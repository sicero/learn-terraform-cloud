const AWS = require('aws-sdk');

AWS.config.update({
  region: 'eu-west-2',  // Replace with your AWS region
});

const cognitoIdentityServiceProvider = new AWS.CognitoIdentityServiceProvider();

const userPoolId = 'your-user-pool-id';  // Replace with your User Pool ID

const usersToCreate = [
  {
    Username: 'user1@example.com',
    Password: 'Password123!',
    UserAttributes: [
      { Name: 'email', Value: 'user1@example.com' },
      // Add more user attributes as needed
    ],
  },
  // Add more user objects as needed
];

const createUserPromises = usersToCreate.map(user => {
  return cognitoIdentityServiceProvider.adminCreateUser({
    UserPoolId: userPoolId,
    Username: user.Username,
    TemporaryPassword: user.Password,
    UserAttributes: user.UserAttributes,
    MessageAction: 'SUPPRESS',  // Suppress the welcome email
  }).promise();
});

Promise.all(createUserPromises)
  .then(() => {
    console.log('Users created successfully');
  })
  .catch(error => {
    console.error('Error creating users:', error);
  });