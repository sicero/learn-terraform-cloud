const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
  const tableName = process.env.DYNAMODB_TABLE_NAME; // Get the DynamoDB table name from environment variables

  // Generate synthetic data
  const itemsToInsert = [];
  for (let i = 1; i <= 10; i++) { // Insert 10 items as an example
    const item = {
      MyPartitionKey: i,
      Name: generateRandomString(10), // Generate a random string of length 10
      // Add more attributes as needed
    };
    itemsToInsert.push(item);
  }

  // Insert data into DynamoDB table
  const putPromises = itemsToInsert.map(item => {
    const params = {
      TableName: tableName,
      Item: item,
    };
    return dynamodb.put(params).promise();
  });

  try {
    await Promise.all(putPromises);
    return {
      statusCode: 200,
      body: 'Data insertion successful',
    };
  } catch (error) {
    console.error('Error inserting data:', error);
    return {
      statusCode: 500,
      body: 'Error inserting data',
    };
  }
};

// Helper function to generate a random string of specified length
function generateRandomString(length) {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  return result;
}
