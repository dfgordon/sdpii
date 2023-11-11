# PowerShell script to create floppy distro
Set-Variable d ($env:USERPROFILE + "\OneDrive\Documents\appleii\DISKS\sdpii.woz")
Remove-Item $d
a2kit mkdsk -d "$d" -t woz2 -o prodos -v sdpii
a2kit get -f dhrlib.json | a2kit put -t any -d "$d" -f dhrlib
a2kit get -f font1.json | a2kit put -t any -d "$d" -f font1
Set-Variable cmd1 ('a2kit get -f paint.bas | a2kit minify -t atxt | a2kit tokenize -a 2049 -t atxt | a2kit put -d "' + $d + '" -f paint -t atok')
Set-Variable cmd2 ('a2kit get -f tile.bas | a2kit minify -t atxt | a2kit tokenize -a 2049 -t atxt | a2kit put -d "' + $d + '" -f tile -t atok')
Set-Variable cmd3 ('a2kit get -f repaint.bas | a2kit minify -t atxt | a2kit tokenize -a 2049 -t atxt | a2kit put -d "' + $d + '" -f repaint -t atok')
cmd /c $cmd1
cmd /c $cmd2
cmd /c $cmd3
a2kit catalog -d $d