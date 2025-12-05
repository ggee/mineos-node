const path = require('path');
const fs = require('fs-extra');
const axios = require('axios');
const Profile = require('./template'); // your Profile class

module.exports = function papertemplate(name) {
  const lowername = name.toLowerCase();
  const titlename = name.charAt(0).toUpperCase() + lowername.slice(1);

  return {
    name: titlename,
    request_args: {
      url: `https://api.papermc.io/v2/projects/${lowername}`,
      json: true
    },

    handler: function(profile_dir, body, callback) {
      try {
        const promises = body.versions.map(version => {
          return axios({ url: `https://api.papermc.io/v2/projects/${lowername}/versions/${version}/` })
            .catch(err => {
              if (err.response && err.response.status === 404) {
                console.warn(`Version ${version} not found (404). Skipping.`);
                return null;
              } else {
                console.error(`Error fetching version ${version}:`, err.message);
                return null;
              }
            });
        });

        Promise.allSettled(promises).then(results => {
          const items = [];
          let weight = 0;

          results.forEach(result => {
            if (result.status === 'fulfilled' && result.value) {
              const response = result.value;

              if (!response.data.builds || response.data.builds.length === 0) return;

              const build = response.data.builds[response.data.builds.length - 1];
              const splitPath = response.request.path.split('/');
              const ver = splitPath[splitPath.length - 2];

              const item = new Profile();
              item.id = `${titlename}-${ver}-${build}`;
              item.group = lowername;
              item.webui_desc = `Latest ${titlename} build for ${ver}`;
              item.weight = weight;
              item.filename = `${lowername}-${ver}-${build}.jar`;
              item.url = `${response.request.res.responseUrl}builds/${build}/downloads/${lowername}-${ver}-${build}.jar`;
              item.downloaded = fs.existsSync(path.join(profile_dir, item.id, item.filename));
              item.version = ver;
              item.release_version = ver;
              item.type = 'release';

              items.push(item);
              weight++;
            } else if (result.status === 'rejected') {
              console.warn('Skipped a version due to error:', result.reason.message);
            }
          });

          callback(null, items);
        });
      } catch (err) {
        console.error('Handler exception:', err);
        callback(err);
      }
    }
  };
};

