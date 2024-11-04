#!/bin/bash

array=("arr1" "arr2" "arr3")
for element in "${array[@]}"; do
    case ${element} in
    1)
        cmd
        ;;

    2)
        cmd
        ;;

    3)
        cmd
        ;;

    *)
        cmd
        ;;
    esac
done
