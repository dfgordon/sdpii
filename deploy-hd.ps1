# PowerShell script to deploy to development directory
Set-Variable d ($env:USERPROFILE + "\OneDrive\Documents\appleii\DISKS\microdrive-prodos-working.po")
Set-Variable f1 "programming/merlin/sdpii/dhrlib.s"
Set-Variable f2 "programming/merlin/sdpii/paint"
Set-Variable f3 "programming/merlin/sdpii/tile"
a2kit delete -d $d -f $f1
a2kit delete -d $d -f $f2
a2kit delete -d $d -f $f3
Set-Variable cmd1 ('a2kit get -f dhrlib.S | a2kit tokenize -t mtxt | a2kit put -d "' + $d + '" -f ' + $f1 + ' -t mtok')
Set-Variable cmd2 ('a2kit get -f paint.bas | a2kit minify -t atxt | a2kit tokenize -a 2049 -t atxt | a2kit put -d "' + $d + '" -f ' + $f2 + ' -t atok')
Set-Variable cmd3 ('a2kit get -f tile.bas | a2kit minify -t atxt | a2kit tokenize -a 2049 -t atxt | a2kit put -d "' + $d + '" -f ' + $f3 + ' -t atok')
cmd /c $cmd1
cmd /c $cmd2
cmd /c $cmd3
a2kit catalog -d $d -f programming/merlin/sdpii