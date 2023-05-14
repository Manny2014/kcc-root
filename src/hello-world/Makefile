
plogin:
	gcloud auth print-access-token | podman login -u oauth2accesstoken --password-stdin us-central1-docker.pkg.dev

pbuild:
	podman build -t us-central1-docker.pkg.dev/dev-primary-003/ar-sample/hello-world:v5 .