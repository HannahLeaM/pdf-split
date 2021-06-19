#!/bin/bash

	#GetBinaries
MyPDFTK=$(which pdftk) || exit 1
MyLESS=$(which less) || exit 1
MyGREP=$(which grep) || exit 1
MyCUT=$(which cut) || exit 1
MySED=$(which sed) || exit 1
MyCAT=$(which cat) || exit 1

	#Declare Variables
TempDir="/home/$USER/.pdfsplit/tmp"
declare -a MatchingFiles
declare -a StartingFiles
declare -a EndingFiles
NACounter=0

	#Check TEMP DIR
if [ ! -d "$TempDir" ]
then
	mkdir -p $TempDir
fi

chmod -R +rw $TempDir

	#FUNCTIONS
merger () {
	local var StartingPage=$1
	local var EndPage=$2
	local var Run=$3

	TrueOutFile=$(echo $OutputFile | sed "s/.pdf/-$Run/g")
	TrueOutFile=$(echo "$TrueOutFile.pdf")

	#CurrentLocation=$(GetLocation $TempDir/${StartingFiles[$i]})
  #CurrentAccount=$(GetAccount $TempDir/${StartingFiles[$i]})
  #SortedOutFile=$(CreateFilePath $CurrentLocation $CurrentAccount)

	echo "Merge from $StartingPage to $EndPage into $TrueOutFile" && $MyPDFTK $InputFile cat $StartingPage-$EndPage output $TrueOutFile > /dev/null
	#echo "Merge from $StartingPage to $EndPage into $SortedOutFile" && $MyPDFTK $InputFile cat $StartingPage-$EndPage output "$SortedOutFile" > /dev/null
}

GetLocation () {
	local var CurrentFile=$1

	local var CurrentLocation=$(less $CurrentFile | grep "Konto:" |  cut -d: -f2 | cut -d' ' -f2)
	echo $CurrentLocation
}

GetAccount () {
	local var CurrentFile=$1

	local var CurrentAccount=$(less $CurrentFile | grep "Konto:" |  cut -d: -f2 | cut -d' ' -f3)
	echo $CurrentAccount
}

CreateFilePath () {
	local var Location=$1
	local var Account=$2

	if [ -z "$Location" ]
	then
		Location="111111"
	fi

	if [ -z "$Account" ]
	then
		Account="$NACounter-Konto_NA"
	fi

	FilePath_TEMP=$(echo $TrueOutFile | sed 's|\(.*\)/.*|\1|')
	PathOut=$(echo "$FilePath_TEMP/fertig")

	for dir in $PathOut/*
	do
		echo "$dir" | grep $Location > /dev/null
		if [ $? -eq 0 ]
		then
			FuncOut=$(echo "$dir/$Account.pdf")
			echo $FuncOut
		fi
	done

	if [ -z "$FuncOut" ]
	then
		echo "$PathOut/$Location_$Account.pdf"
	fi

	NACounter=$((NACounter+1))
}

OCR () {
	local var InputFile=$1

	echo "OCR In: " $InputFile

	OCROutFile=$(echo $InputFile | sed "s/.pdf/-OCR/2")
        OCROutFile=$(echo "$OCROutFile.pdf")

	echo "OCR Out: " $OCROutFile

	ocrmypdf -l deu --tesseract-oem 3 $InputFile $OCROutFile > /dev/null
	rm -fr $InputFile
}

	#Read FLAGS
while getopts "I:O:" option
do
	case $option in
		I)
			if [ ! -z $OPTARG ]
			then
				InputFile=$OPTARG
			else
				echo "No Input defined!" && exit 1
			fi
			;;

		O)
			if [ ! -z $OPTARG ]
			then
				OutputFile=$OPTARG
			else
				echo "No Output defined!" && exit 1
			fi
			;;
	esac
done

	#UserInput
read -p "Enter pattern to grep: " GrepPattern

echo "Splitting in progress ..."

	#Get PageCount
PageCount=$(pdftk $InputFile dump_data | grep NumberOfPages | cut -d" " -f2) > /dev/null

	#Split into single pages
for ((i = 1; i <= $PageCount; i++));
do
	if [ $i -lt 10 ]
	then
		$MyPDFTK $InputFile cat $i output $TempDir/temp-split_0$i.pdf > /dev/null
	else
		$MyPDFTK $InputFile cat $i output $TempDir/temp-split_$i.pdf > /dev/null
	fi
done

echo "Splitted $PageCount pages!"

	#Perform OCR
echo "Performing OCR Text recognition on $PageCount pages [might take some time]..."

for file in $TempDir/*
do
	OCR $file
done

echo "Matching $PageCount Files to pattern ..."

	#Check content and create file descriptors
for file in $TempDir/*
do
	$MyLESS $file | $MyGREP "$GrepPattern" > /dev/null
	if [ $? -eq 0 ]
	then
		MatchingFiles[${#MatchingFiles[@]}]=$file
	fi
done

	#Echo Matching Pages
MatchingFileCount=${#MatchingFiles[*]}
echo "Files Matching: $MatchingFileCount"
for value in "${MatchingFiles[@]}"
do
	Trunc_TEMP=$(echo ${value##*/})
	StartingFiles[${#StartingFiles[@]}]=$Trunc_TEMP
done

for ((i = 1; i <= $MatchingFileCount; i++));
do
	Run=$(echo $i)
	SkipI=$(($i + 1))
	StartNumber=$(echo ${StartingFiles[$i]} | cut -d_ -f2 | cut -d- -f1)
	EndNumber=$(echo ${StartingFiles[$SkipI]} | cut -d_ -f2| cut -d- -f1)
	EndNumber=$(echo $EndNumber | sed 's/^0*//')
	EndNumber=$(($EndNumber - 1))

	if [ $EndNumber -lt 10 ]
	then
		if [ $EndNumber -ne "-1" ]
		then
			EndNumber=$(echo "0$EndNumber")
		else
			EndNumber=""
		fi
	fi

	if [ -z $EndNumber ]
	then
		EndNumber=$(echo $PageCount)
	fi

	if [ -z $StartNumber ]
	then
		StartNumber=$(echo $PageCount)
	fi

	if [ $StartNumber -ne $PageCount ]
	then
		merger $StartNumber $EndNumber $Run
		((NACounter++))
	fi
done

	#CleanUp
echo "Cleaning up temp directory ..."
rm -fr $TempDir/*.txt
rm -fr $TempDir/*.pdf
