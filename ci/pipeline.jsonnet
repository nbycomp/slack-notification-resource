local action = import 'action.libsonnet';
local job = import 'job.libsonnet';
local resource = import 'resource.libsonnet';

local component = 'slack-notification-resource';
local repo = 'git@github.com:nbycomp/slack-notification-resource.git';

local git_repo = resource.repo('git-repo', repo);
local image_version = resource.version(component, 'develop') {
  source+: {
    initial_version: '0.1.7',
  },
};
local registry_image = resource.image(component, 'registry.nearbycomputing.com/ci/slack-notification-resource', '0.1.7');

{
  resources: [
    resource.repo_ci_tasks,
    resource.repo_pipeline(repo),
    git_repo,
    image_version,
    registry_image,
  ],

  jobs: [
    job.update_pipeline,
    {
      name: 'build-resource-image',
      public: true,
      serial: true,
      plan: [
        {
          in_parallel: [
            {
              get: 'repo',
              resource: git_repo.name,
              trigger: true,
            },
            action.get_version(image_version.name, 'patch'),
            action.get_ci_tasks,
          ],
        },
        action.build,
        {
          put: registry_image.name,
          params: {
            image: 'image/image.tar',
            additional_tags: 'version/version',
          },
        },
        {
          put: image_version.name,
        },
      ],
    },
  ],
}
