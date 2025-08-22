const { build } = require('vite');

async function runBuild() {
  try {
    console.log('开始构建项目...');
    await build({
      configFile: './vite.config.js'
    });
    console.log('构建完成！');
  } catch (error) {
    console.error('构建失败:', error);
    process.exit(1);
  }
}

runBuild();
