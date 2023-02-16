# Cloud Resume Challenge Backend

![Alt text](diagram.jpg?raw=true "Title")

[Frontend Repo](https://github.com/sallen222/cloudresume)

## Summary
This repo contains the backend of my cloud resume project inspired by the [Cloud Resume Challenge](https://cloudresumechallenge.dev/docs/the-challenge/aws/).

## Infrastructure
The backend consists of two AWS Lambda functions written in python that increment and retrieve data from DynamoDB. These functions are exposed via API Gateway and called by the projects frontend website.

This repo contains a unit test for both lambda functions that uses the moto library create a simulatyed DynamoDB table. 

## Deployment
These resources are built and deployed automatically using Terraform and Github Actions. When changes are pushed to main, the functions are tested and automatically deployed.