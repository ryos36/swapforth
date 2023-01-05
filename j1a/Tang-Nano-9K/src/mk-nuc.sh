NUC_HEX_FILE=${1:-../../build/nuc.hex}
NUC_MI_FILE=${2:-nuc.mi}

cat << NUC_MI_HEAD > $NUC_MI_FILE
#File_format=Hex
#Address_depth=4096
#Data_width=16
NUC_MI_HEAD

head -4096 $NUC_HEX_FILE >> $NUC_MI_FILE
