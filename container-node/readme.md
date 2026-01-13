### Docker Run Command:

```
docker run --name feedback-app -d -p 3000:80 -v feedback:/app/feedback -v "./:/app" --env-file ./.env --rm feedback-node:volumes
```

### Env Example: 
```
PORT=8080
REGISTRY=docker.io
NAMESPACE=example
IMAGE_NAME=app-example
```