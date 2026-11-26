import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
const url=process.env.SUPABASE_URL?.replace(/\/$/,'');
const key=process.env.SUPABASE_PUBLISHABLE_KEY;
if (!url) throw Error('SUPABASE_URL is missing');
if (!key) throw Error('SUPABASE_PUBLISHABLE_KEY is missing');
if (!/^https:\/\/[a-z0-9-]+\.supabase\.co$/i.test(url))
  throw Error('SUPABASE_URL format is incorrect');
if(!key.startsWith('sb_publishable_')) {let claims;try{claims=JSON.parse(Buffer.from(key.split('.')[1],'base64url'))}catch{} if(claims?.role!=='anon') throw Error('Only publishable or anon key allowed');}
const src=readFileSync('src/index.html','utf8');
const config=JSON.stringify({url,key}).replaceAll('<','\\u003c');
const html=src.replace('__MMA_CONFIG__',()=>config);
mkdirSync('dist',{recursive:true});writeFileSync('dist/index.html',html);writeFileSync('dist/.nojekyll','');
