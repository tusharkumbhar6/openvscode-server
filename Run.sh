# macOS/Linux
mkdir -p ./workspace
docker run --rm -it \
  -p 3000:3000 \
  -e PASSWORD='test123' \
  -e OPENVSCODE_SERVER_HOST=0.0.0.0 \
  -e OPENVSCODE_SERVER_PORT=3000 \
  -v "$(pwd)/workspace:/home/workspace" \
  --name ovscode \
  tusharkumbhar6/openvscode-spark-image:local