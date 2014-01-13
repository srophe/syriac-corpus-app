$( "#moreInfo" ).click(function() {
  $( "#citation" ).toggle( "slow", function() {
    $( "#moreInfo" ).toggle();
  });
});

// This script sets OSName variable as follows:
// "Windows"    for all versions of Windows
// "MacOS"      for all versions of Macintosh OS
// "Linux"      for all versions of Linux
// "UNIX"       for all other UNIX flavors 
// "Unknown OS" indicates failure to detect the OS

var OSName="Unknown OS";
if (navigator.appVersion.indexOf("Win")!=-1) OSName="Windows";
if (navigator.appVersion.indexOf("Mac")!=-1) OSName="MacOS";
if (navigator.appVersion.indexOf("X11")!=-1) OSName="UNIX";
if (navigator.appVersion.indexOf("Linux")!=-1) OSName="Linux";

if(OSName == "MacOS"){
   document.getElementById('get-font').style.display = "block";
}
else if(OSName == "Linux"){
   document.getElementById('get-font').style.display = "block";
}
else{
   document.getElementById('get-font').style.display = "none";
}

