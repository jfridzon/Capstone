function check(condition,message){if(!condition)throw Error(message)}
for(const c of cases){
  inputs.forEach((input,i)=>{if(input.checked!==c.features.includes(data.features[i]))input.click()});
  el("budget").value=c.limit==="Inf"?"Infinity":c.limit;
  el("budget").dispatchEvent(new Event("change"));
  const mask=c.features.reduce((m,f)=>m|(1<<data.features.indexOf(f)),0);
  const result=recommend(mask,Number(el("budget").value));
  check(result.n===c.count,"Question count");
  check(JSON.stringify([...document.querySelectorAll(".model")].map(x=>x.textContent))===JSON.stringify(c.ids),"Rendered ranking");
  result.models.forEach((m,i)=>check(Math.abs(m.score-c.scores[i])<1e-9,"Fitted score"));
}
el("clear").click();check(inputs.every(i=>!i.checked),"Clear");
el("preset").value="math";el("preset").dispatchEvent(new Event("change"));
check(inputs[data.features.indexOf("math")].checked,"Preset");
el("validate").click();check(!el("dashboard").hidden && el("finder").hidden,"Dashboard");
for(const option of el("period").options){
  el("period").value=option.value;el("period").dispatchEvent(new Event("change"));
  const actual=[...el("votechart").querySelectorAll("strong")].map(e=>e.textContent);
  const row=data.comparison.find(r=>r.fold===option.value);
  check(actual[2]===row.auc_big_01.toFixed(4),"Dashboard vote chart");
  check(el("modelchart").querySelectorAll("strong")[3].textContent===data.ladder[3][option.value==="mean"?"Mean_CV":"Fold_"+option.value].toFixed(4),"Dashboard model chart");
}
el("choose").click();check(!el("finder").hidden,"Back to recommendations");
document.body.dataset.test="passed";
