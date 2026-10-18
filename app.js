const cfg=window.MONO_CONFIG||{};
const ready=cfg.SUPABASE_URL&&cfg.SUPABASE_ANON_KEY&&!cfg.SUPABASE_URL.includes("PASTE_")&&!cfg.SUPABASE_ANON_KEY.includes("PASTE_");
const money=n=>new Intl.NumberFormat("id-ID",{style:"currency",currency:"IDR",maximumFractionDigits:0}).format(Number(n)||0);
const escapeHtml=s=>String(s??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
document.getElementById("year").textContent=new Date().getFullYear();
let supa=null,allProducts=[],allCollections=[],settings={};

// Logo bawaan (dipakai bila logo_url di admin dikosongkan).
const DEFAULT_LOGO='<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="MONO FINDS"><rect x="1" y="1" width="38" height="38" rx="11" fill="#252525"/><path d="M10 29V11h4.6l5.4 9.4L25.4 11H30v18h-4V17.6l-5.4 9.2h-1.2L14 17.6V29z" fill="#ffffff"/></svg>';

// Isi teks; baris baru (\n) diubah menjadi <br> tanpa memakai innerHTML.
function setMultiline(el,value){el.textContent="";String(value).split("\n").forEach((part,i)=>{if(i)el.appendChild(document.createElement("br"));el.appendChild(document.createTextNode(part));});}
function applyLogo(){const box=document.getElementById("logomark");if(!box)return;const url=(settings.logo_url||"").trim();box.innerHTML="";if(!url){box.innerHTML=DEFAULT_LOGO;return;}const img=document.createElement("img");img.src=url;img.alt="";img.loading="lazy";img.onerror=()=>{box.innerHTML=DEFAULT_LOGO;};box.appendChild(img);}
function applySettings(){
  document.querySelectorAll("[data-setting]").forEach(el=>{const v=settings[el.dataset.setting];if(v!==undefined&&v!=="")setMultiline(el,v);});
  document.querySelectorAll("[data-setting-placeholder]").forEach(el=>{const v=settings[el.dataset.settingPlaceholder];if(v)el.setAttribute("placeholder",v);});
  applyLogo();
}

if(ready){supa=window.supabase.createClient(cfg.SUPABASE_URL,cfg.SUPABASE_ANON_KEY);loadAll();}
else {applySettings();document.getElementById("status").textContent="Demo katalog — sambungkan Supabase untuk mengaktifkan database publik.";allProducts=[
{id:"p1",name:"Kaos Polo Pria Onion",price:115000,category:"Fashion pria",variants:"Black, Brown, Ivory, Green",image_url:"",affiliate_url:"",description:"",collection_code:"BOYSTYLE01"},
{id:"p2",name:"Ventela [Original] V23 Low White Brown",price:293080,category:"Sepatu",variants:"White Brown",image_url:"",affiliate_url:"https://vt.tokopedia.com/t/ZS9UmmrNJhsKM-yhh3b/",description:"",collection_code:"BOYSTYLE02"}];render(allProducts);}

async function loadAll(){await Promise.all([loadSettings(),loadProducts()]);}

// Tabel site_settings mungkin belum ada (migrasi belum dijalankan) -> pakai teks bawaan.
// applySettings() tetap dipanggil agar logo bawaan selalu tampil.
async function loadSettings(){const {data,error}=await supa.from("site_settings").select("key,value");if(!error&&data){settings={};data.forEach(r=>{settings[r.key]=r.value;});}applySettings();}

async function loadProducts(){const [p,c]=await Promise.all([supa.from("products").select("id,name,price,category,variants,image_url,affiliate_url,description,collection_id,collections(code,name)").eq("is_active",true).order("created_at",{ascending:false}),supa.from("collections").select("id,code,name").order("code")]);if(p.error){document.getElementById("status").textContent="Katalog belum tersedia. Pastikan schema database sudah dijalankan.";return;}allCollections=c.data||[];allProducts=(p.data||[]).map(x=>({...x,collection_code:x.collections?.code||"",collection_name:x.collections?.name||""}));document.getElementById("status").textContent=allProducts.length?"":"Belum ada produk dalam katalog.";render(allProducts);}

function render(products){const el=document.getElementById("products");el.innerHTML="";document.getElementById("count").textContent=products.length+" produk";if(!products.length){el.innerHTML='<div class="empty">Kode tidak ditemukan atau koleksi ini belum memiliki produk.</div>';return;}for(const p of products){const card=document.createElement("article");card.className="card";const image=p.image_url?`<img src="${escapeHtml(p.image_url)}" alt="${escapeHtml(p.name)}" loading="lazy" onerror="this.remove()">`:"";const link=p.affiliate_url?`<a class="linkbtn" href="${escapeHtml(p.affiliate_url)}" target="_blank" rel="noopener noreferrer">Lihat produk ↗</a>`:'<span class="linkbtn disabled">Link produk segera hadir</span>';card.innerHTML=`<div class="visual"><span class="pill">${escapeHtml(p.collection_code||"MONO FINDS")}</span>${image||`<div class="placeholder">${escapeHtml(p.name)}<br>Foto produk belum ditambahkan</div>`}</div><div class="details"><div class="category">${escapeHtml(p.category||"Pilihan MONO")}</div><h3>${escapeHtml(p.name)}</h3><div class="price">${money(p.price)}</div><div class="meta">${p.variants?"Variasi: "+escapeHtml(p.variants):""}${p.description?"<br>"+escapeHtml(p.description):""}</div>${link}</div>`;el.appendChild(card);}}

document.getElementById("searchForm").addEventListener("submit",e=>{e.preventDefault();const code=document.getElementById("codeInput").value.trim().toUpperCase();const filtered=code?allProducts.filter(p=>(p.collection_code||"").toUpperCase()===code):allProducts;document.getElementById("collectionTitle").textContent=code?(allCollections.find(c=>c.code.toUpperCase()===code)?.name||code):(settings.collection_title||"Semua produk");document.getElementById("status").textContent=filtered.length?"":"Tidak ada produk untuk kode tersebut.";render(filtered);});
