const AWS = require('aws-sdk');
const { faker } = require('@faker-js/faker');

const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
  const tableName = process.env.DYNAMODB_TABLE_NAME; // Get the DynamoDB table name from environment variables

  // Generate synthetic data
  const itemsToInsert = [];
  for (let i = 1; i <= 10; i++) { // Insert 10 items as an example
    const item = {
        ID: i.toString(),
        Username: faker.internet.userName(),
        Email: faker.internet.email(),
        Avatar: faker.image.avatar(),
        Password: faker.internet.password(),
        Birthdate: faker.date.birthdate().toISOString() ,
        RegisteredAt: faker.date.past().toISOString() ,
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

