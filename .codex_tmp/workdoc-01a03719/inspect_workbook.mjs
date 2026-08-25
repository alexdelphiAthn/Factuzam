import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/Users/V3607/Desktop/Documento_trabajo_5_Documento de trabajo 06_08_2026 06_02.xlsx";
const outputDir = "C:/DISCO_DURO/proyectos/Factuzam/.codex_tmp/workdoc-01a03719/rendered";

const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);

const summary = await workbook.inspect({
  kind: "workbook,sheet,table,definedName",
  maxChars: 12000,
  tableMaxRows: 20,
  tableMaxCols: 30,
  tableMaxCellChars: 120,
});
console.log("SUMMARY");
console.log(summary.ndjson);

const sheets = await workbook.inspect({
  kind: "sheet",
  include: "id,name",
  maxChars: 6000,
});
console.log("SHEETS");
console.log(sheets.ndjson);

await fs.mkdir(outputDir, { recursive: true });
const sheetLines = String(sheets.ndjson).split(/\r?\n/).filter(Boolean);
for (const line of sheetLines) {
  let record;
  try { record = JSON.parse(line); } catch { continue; }
  const sheetName = record.name ?? record.sheetName;
  if (!sheetName) continue;
  const detail = await workbook.inspect({
    kind: "region,formula,computedStyle",
    sheetId: record.id ?? sheetName,
    maxChars: 20000,
    tableMaxRows: 100,
    tableMaxCols: 40,
    options: { maxResults: 300 },
  });
  console.log(`DETAIL ${sheetName}`);
  console.log(detail.ndjson);
  const preview = await workbook.render({
    sheetName,
    autoCrop: "all",
    scale: 2,
    format: "png",
  });
  const safeName = sheetName.replace(/[\\/:*?"<>|]/g, "_");
  await fs.writeFile(path.join(outputDir, `${safeName}.png`), new Uint8Array(await preview.arrayBuffer()));
}
