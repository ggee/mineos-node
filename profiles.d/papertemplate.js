const path = require('path');
const fs = require('fs-extra');
const axios = require('axios');
const Profile = require('./template'); // your Profile class

module.exports = function papertemplate(name) {
  const lowername = name.toLowerCase();
  const titlename = name.charAt(0).toUpperCase() + lowername.slice(1);
  const versionType = version => /-(pre|rc)-?\d*$/i.test(version) ? 'snapshot' : 'release';

  return {
    name: titlename,
    request_args: {
      url: `https://fill.papermc.io/v3/projects/${lowername}`,
      json: true
    },

    handler: function(profile_dir, body, callback) {
      try {
        const versions = Object.values(body.versions || {}).reduce((all, versionGroup) => {
          return all.concat(versionGroup);
        }, []);

        const promises = versions.map(version => {
          return axios({ url: `https://fill.papermc.io/v3/projects/${lowername}/versions/${version}` })
            .then(response => {
              if (!response.data.builds || response.data.builds.length === 0) return null;

              const build = response.data.builds[0];
              return axios({
                url: `https://fill.papermc.io/v3/projects/${lowername}/versions/${version}/builds/${build}`
              }).then(buildResponse => ({
                build,
                version,
                time: buildResponse.data.time,
                download: buildResponse.data.downloads && buildResponse.data.downloads['server:default']
              }));
            })
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
              const buildInfo = result.value;
              const build = buildInfo.build;
              const ver = buildInfo.version;
              const download = buildInfo.download;
              if (!download || !download.name || !download.url) return;

              const item = new Profile();
              item.id = `${titlename}-${ver}-${build}`;
              item.group = lowername;
              item.webui_desc = `Latest ${titlename} build for ${ver}`;
              item.weight = versions.length - weight;
              item.filename = download.name;
              item.url = download.url;
              item.downloaded = fs.existsSync(path.join(profile_dir, item.id, item.filename));
              item.time = buildInfo.time;
              item.releaseTime = buildInfo.time;
              item.version = ver;
              item.release_version = ver;
              item.type = versionType(ver);

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

