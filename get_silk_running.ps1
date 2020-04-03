# Parameters:
# input file where hostnames are stored
# password for autotest user
param (
  [string]$input_file = $(throw "-input_file is required."),
  [string]$password = $(throw "-password is required.")
)

# variable for html title
$TARGET_HOSTS = [io.path]::GetFileNameWithoutExtension($input_file)

# build output filename
$OUTPUT_FILE = "get_silk_running." + $TARGET_HOSTS + ".html"
Remove-Item -Path $OUTPUT_FILE

# get hostnames from $input_file
$Computers = get-content $input_file

# credentials
$pw = convertto-securestring -AsPlainText -Force -String $password
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "<USER>",$pw

# HTML report header
$HTML_HEAD = "
<head>
<title>SilkTest processes are running on $TARGET_HOSTS </title>
<meta charset=`"utf-8`">
<link rel=`"stylesheet`" href=`"https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css`" integrity=`"sha384-MCw98/SFnGE8fJT3GXwEOngsV7Zt27NXFoaoApmYm81iuXoPkFOJwJ8ERdknLPMO`" crossorigin=`"anonymous`">
<script src=`"https://code.jquery.com/jquery-3.3.1.slim.min.js`" integrity=`"sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo`" crossorigin=`"anonymous`"></script>
<script src=`"https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.3/umd/popper.min.js`" integrity=`"sha384-ZMP7rVo3mIykV+2+9J3UJ46jBk0WLaUAdn689aCwoqbBJiSnjAK/l8WvCWPIPm49`" crossorigin=`"anonymous`"></script>
<script src=`"https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/js/bootstrap.min.js`" integrity=`"sha384-ChfqqxuZUCnJSK3+MXmPNIyE6ZbWh2IMqE241rYiqJxyMiZ6OW/JmZQ5stwEULTy`" crossorigin=`"anonymous`"></script>
<!-- Enable DataTables --> 
<link rel=`"stylesheet`" href=`"https://cdn.datatables.net/1.10.19/css/jquery.dataTables.min.css`" crossorigin=`"anonymous`">
<script src=`"https://cdn.datatables.net/1.10.19/js/jquery.dataTables.min.js`" crossorigin=`"anonymous`"></script>
<script src=`"https://cdn.datatables.net/plug-ins/1.10.19/sorting/natural.js`" crossorigin=`"anonymous`"></script>
<script>
`$(document).ready(function () {
`$('#Silk_Details').DataTable({
order: [ 0, 'asc' ],
paging: false,
searching: false,
columnDefs: [
       { type: 'natural', targets: 0 }
     ]});
`$('.dataTables_length').addClass('bs-select');
});
</script>
</head>
<body>
<div class=`"container-fluid`">
<h2><p>SilkTest processes are running on $TARGET_HOSTS </h2>
<table id=`"Silk_Details`" style=`"width: auto;`" class=`"table  table-bordered  table-hover`">
<thead>
<tr>
<th>Hostname</th>
<th>Process</th>
<th>Count</th>
</tr>
</thead>
<tbody>"

# HTML report footer
$HTML_FOOTER = '
</tbody>
</table>
</div>
</body>'

echo $HTML_HEAD | Out-File $OUTPUT_FILE -append

foreach($Computer in $Computers) {
  Invoke-Command -AsJob -JobName Get_SilkTest_Running -ComputerName $Computer -credential $cred -ScriptBlock {
    $Check_Command = Get-Process -Name partner, runtime -ErrorAction SilentlyContinue
	if ($Check_Command) {
	  #result:
	  "<tr>
	  <td>$($env:computername)</td>
	  <td>"+$Check_Command.ProcessName+"</td>
      <td>"+($Check_Command | Measure-Object).count+"</td>
	  </tr>"
	}
  }
}

# wait for the job to complete    
wait-job -name Get_SilkTest_Running

# get all of teh job results
$results=receive-job -name Get_SilkTest_Running

$results | Out-File $OUTPUT_FILE -append

# remove job and cleanup
Get-Job -name Get_SilkTest_Running | Remove-Job


# write date to html-report
$DATE=Get-Date
echo "<br>Generated: $DATE<br><br>" | Out-File $OUTPUT_FILE -append

echo $HTML_FOOTER | Out-File $OUTPUT_FILE -append
