# pdf2png.ps1 — PDF 를 쪽마다 PNG 로 굽는다. 이 컴퓨터에는 poppler·ghostscript·
#               ImageMagick·python 이 없고, Windows 가 들고 있는 WinRT
#               Windows.Data.Pdf 만 있다. Read 도구가 PDF 를 열지 못할 때 쓴다.
#               Renders each page of a PDF to PNG through the WinRT PDF API,
#               the only rasteriser present on this machine.
#
#   powershell -ExecutionPolicy Bypass -File _tools/pdf2png.ps1 `
#              -Pdf lectures/노트_261124.pdf -OutDir <scratchpad>/note -Width 1700
#
#   굽은 PNG 는 작업폴더 밖(스크래치패드)에 둔다 — 볼트에 넣지 않는다.
#   Write the PNGs outside the vault; they are reading aids, not vault figures.

param(
  [Parameter(Mandatory=$true)][string]$Pdf,
  [Parameter(Mandatory=$true)][string]$OutDir,
  [int]$Width = 1700
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime

$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() |
  Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
                 $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

function Await-Op($op, $type) {
  $m = $asTaskGeneric.MakeGenericMethod($type)
  $t = $m.Invoke($null, @($op))
  $t.Wait(-1) | Out-Null
  $t.Result
}

$asTaskAction = ([System.WindowsRuntimeSystemExtensions].GetMethods() |
  Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
                 -not $_.IsGenericMethod })[0]

function Await-Act($act) {
  $t = $asTaskAction.Invoke($null, @($act))
  $t.Wait(-1) | Out-Null
}

[Windows.Data.Pdf.PdfDocument,Windows.Data.Pdf,ContentType=WindowsRuntime] | Out-Null
[Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime] | Out-Null
[Windows.Storage.Streams.InMemoryRandomAccessStream,Windows.Storage.Streams,ContentType=WindowsRuntime] | Out-Null
[Windows.Storage.Streams.DataReader,Windows.Storage.Streams,ContentType=WindowsRuntime] | Out-Null

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

$full = (Resolve-Path $Pdf).Path
$sf   = Await-Op ([Windows.Storage.StorageFile]::GetFileFromPathAsync($full)) ([Windows.Storage.StorageFile])
$doc  = Await-Op ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($sf))     ([Windows.Data.Pdf.PdfDocument])

Write-Output ("pages=" + $doc.PageCount)

for ($i = 0; $i -lt $doc.PageCount; $i++) {
  $page = $doc.GetPage($i)
  $opts = New-Object Windows.Data.Pdf.PdfPageRenderOptions
  $opts.DestinationWidth = [uint32]$Width
  $ms = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
  Await-Act ($page.RenderToStreamAsync($ms, $opts))
  $size = [int]$ms.Size
  $rd = New-Object Windows.Storage.Streams.DataReader($ms.GetInputStreamAt(0))
  Await-Op ($rd.LoadAsync([uint32]$size)) ([uint32]) | Out-Null
  $bytes = New-Object byte[] $size
  $rd.ReadBytes($bytes)
  $rd.Dispose()
  $ms.Dispose()
  # $page.Close() 는 이 WinRT 투영에 없다 / not projected here
  $name = Join-Path $OutDir ("p{0:d2}.png" -f ($i+1))
  [System.IO.File]::WriteAllBytes($name, $bytes)
  Write-Output ("wrote " + $name + " (" + $size + " bytes)")
}
