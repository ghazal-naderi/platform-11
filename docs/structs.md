## Structs
We aim to make our infrastructure as code as reusable and composable as possible. To fulfil this aim, we have adopted the concept of 'structs'. Yes, its a delightfully over-used term, in use in languages as diverse as C, Go and probable some others, but damn it all, it sounds _cool_. So we use structs. 

## Kubernetes Structs
A Kubernetes struct is essentially a base layer that can be pulled into other projects and then applied using [Kustomize](https://github.com/kubernetes-sigs/kustomize). This 'pull' is achieved in a CI task that takes the code from this repository and copies it into a clients repository. In this way, we can keep it up to date while the project is under our care. Once the project is handed on this approach gives the client their own version of the struct at the time of delivery. This will enable us to hand on the 'complete' codebase without requiring client access to our repos, or via tedious and error-prone copy and paste. 

## Anatomy of a Kubernetes struct
Structs can be found in in the ```/k8s``` directory of this repository. Gaze in awe at its magnificence.

A struct is a complete, workable Kubernetes configuration. This is not to say it has to actually work - just that it is complete. A great many of the values may likely be placeholders, such as secrets. This is fine and expected, most any additional configuration required will be documented in the the struct's README.md. A struct must have a valid ```kustomization.yaml``` file for usage when it is merged into an upstream project. This follows the usual format, and will look something like this:

```
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- crd.yaml
- external-secrets.yaml
- namespace.yaml
```
See the [Kustomize spec](https://kubernetes-sigs.github.io/kustomize/api-reference/glossary/#kustomization) for further details, but basically, for every file in your struct that is to be applied to Kubernetes ensure you have a ```resources:``` entry. 

*TLDR*
- A struct is a valid kubernetes config
- Values should be placeholders
- All structs are documented with README.md
- Every struct has to have a valid Kustomize document

## Anatomy of a Terraform struct
Terraform structs can be found in ```/terraform``` inside this repository.

A struct is a complete, workable Terraform module with sane defaults. It should be capable of spinning up what it says on the tin, provided that the requirements are met and that the correct cloud credentials and regions are passed to Terraform via environment variables. By convention, each contains a ```main.tf```file that contains the initial declaration (and perhaps more) of the resource that should be created.

This is then used in your main Terraform files as a module like so:

````
module "ses" {
  source = "../structs/aws-ses"
  # any custom input variable declarations here
}
````

## Anatomy of a Workflow struct
Workflow structs can be found in ```/workflows``` inside this repository.

A struct is a complete, workable GitHub Action workflow that can be used either as-is or bootstrapped as a template for further configuration. Simply specify the `path` as `.github/workflows` and direct the `name` to the struct directory, eg.

```
packages:
  - name: workflows/all-gather-deps
    path: .github/workflows
    ref: v0.0.2
```

## Using a struct in a project
Once you have completed a struct, you are ready to inflict it on a client. Lucky them! In every client project that uses the structs, you should find a file called ```manifest.yaml``` - if it doesn't exist yet, this may mean that you need to install [a GitHub Actions workflow](https://github.com/11FSConsulting/platform/tree/master/workflows/all-gather-deps)! The manifest lists all structs in use, where they are sourced from, and which version to pull in. This is essentially a form of vendoring back to this repository. Let's take a look at an example:

```
packages:
 - name: k8s/external-dns
   path: k8s/oke/structs/external-dns
   ref: v0.0.2
```

First thing - the ```manifest.yaml``` starts with a ```packages:``` key. If that's missing, amusing errors will ensue. After that comes a list of packages. Each package contains three keys, a ```name```, ```path``` and ```ref```. The name should be the path in this repo to find the struct. So if you have created a new struct called 'shinyCool' in the k8s directory then the name would be ```k8s/shinycool```. The path is where to place the struct in the _clients_ project repository. In our example, if we had a path of: ```k8s/clientco/structs/shinyCool``` then that's where the the struct will be placed. Finally, the ```ref``` is either a Github SHA or tag. 

Using these three tags will do the following when the client project is built:
- Checkout from the ```platform``` repo a copy of the struct located in the repo at the ```name``` path at the Git version ```ref```.
- Copy the struct into the client project
- Check it in

*TLDR;* 
- Requires: [all-gather-deps](https://github.com/11FSConsulting/platform/tree/master/workflows/all-gather-deps)
- Every client project needs a ```manifest.yaml``` in the root of the project
- The manifest.yaml needs to start with a ```packages:``` key
- Each package has a ```name```, ```path``` and ```ref``` key
- The ```name``` is the path to struct in this repo. 
- The ```path``` is where it is placed in the client repo
- The ```ref``` is the git sha or tag to pull
- Optionally, the ```release``` tag can be configured for certain Helm-rendered k8s structs to adjust the release prefix (default is `platform`)
- The build process copies the struct at the right version from the platform repo to the target client repo
