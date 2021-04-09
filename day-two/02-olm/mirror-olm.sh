#!/usr/bin/env bash

# Mirror the catalog image to a private registry
function mirror_catalog_image {

    ocp_release=${1}
    catalog_name=${2}
    catalog_image=${3}
    registry_auth=${4}
    arch=${5}

    # Display catalogs image content
    oc image info \
        registry.redhat.io/redhat/${catalog_name}-index:v${ocp_release} \
            --registry-config=${registry_auth} \
            --filter-by-os=${arch}

    # Mirror index image
    oc image mirror \
        registry.redhat.io/redhat/${catalog_name}-index:v${ocp_release} ${catalog_image} \
            --registry-config=${registry_auth} \
            --filter-by-os=${arch} \
            --insecure=true
}

# Download the database catalog content for a database
function download_catalog_db {

    catalog_name=${1}
    catalog_image=${2}
    catalog_repository=${3}
    catalog_path="catalogs/${catalog_name}"
    catalog_image_fs="${catalog_path}/image"
    registry_auth=${4}

    # Download catalog database
    mkdir -p ${catalog_image_fs}

    oc adm catalog mirror \
        ${catalog_image} ${catalog_repository} \
            --manifests-only \
            --to-manifests=${catalog_path} \
            --path="/:${catalog_image_fs}" \
            --registry-config=${registry_auth} \
            --icsp-scope="registry" \
            --filter-by-os=".*" \
            --insecure=true

    # # Get the list of operators in the catalog
    sqlite3 ${catalog_image_fs}/database/index.db \
        "select operatorbundle_name from related_image group by operatorbundle_name;" \
            > ${catalog_path}/index.txt
}

# Mirror the images for an operator
function mirror_operator_images {

    catalog_path=${1}
    operator_name=${2}
    operator_path="${catalog_path}/operators/${operator_name}"
    registry_auth=${3}

    # Create operators folder
    mkdir -p ${operator_path}
    rm -f ${operator_path}/images.txt

    # Get updated list of operator images

    operator_images=(`sqlite3 ${catalog_path}/image/database/index.db \
        "select image from related_image where operatorbundle_name like '${operator_name}%';"`)

    for image in "${operator_images[@]}"; do
        echo ${image}
        grep ${image} ${catalog_path}/mapping.txt \
            >> ${operator_path}/images.txt
    done

    operator_bundle_image=(`sqlite3 ${catalog_path}/image/database/index.db \
        "select bundlepath from operatorbundle where name like '${operator_name}%';"`)

    echo ${operator_bundle_image}
    grep ${operator_bundle_image} ${catalog_path}/mapping.txt \
        >> ${operator_path}/images.txt

    # Mirror filtered operators
    # oc image mirror \
    #     --filename=${operator_path}/images.txt \
    #     --registry-config=${registry_auth} \
    #     --filter-by-os=".*" \
    #     --insecure=true
}

# CLI command for mirror_catalog_image function
function cmd_mirror_catalog {
    while test $# -gt 0; do
        case "$1" in
            --ocp-release*)
                export ocp_release=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            --catalog-name*)
                export catalog_name=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            --catalog-image*)
                export catalog_image=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            --registry-auth*)
                export registry_auth=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            --arch*)
                export arch=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            *)
                break
            ;;
        esac
    done

    mirror_catalog_image ${ocp_release} ${catalog_name} ${catalog_image} ${registry_auth} ${arch}
}

# CLI command for download_catalog_db function
function cmd_download_db {
    while test $# -gt 0; do
        case "$1" in
            --catalog-name*)
                export catalog_name=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            --catalog-image*)
                export catalog_image=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            --catalog-repository*)
                export catalog_repository=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            --registry-auth*)
                export registry_auth=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            *)
                break
            ;;
        esac
    done

    download_catalog_db ${catalog_name} ${catalog_image} ${catalog_repository} ${registry_auth}
}

# CLI command for mirror_operator_images function
function cmd_mirror_operator {
    while test $# -gt 0; do
        case "$1" in
            --catalog-path*)
                export catalog_path=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            --operator-name*)
                export operator_name=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            --registry-auth*)
                export registry_auth=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            *)
                break
            ;;
        esac
    done

    mirror_operator_images ${catalog_path} ${operator_name} ${registry_auth}
}

# CLI command for usage
function cmd_usage {
    echo "${1} [options] [arguments]"
    echo " "
    echo "options:"
    echo "  mirror-catalog      Mirror catalog image"
    echo "  download-db         Download catalog database"
    echo "  mirror-operator     Mirror operator images"
}

# Main function
case "$1" in
    mirror-catalog)
        echo "Mirroring catalog..."
        shift
        cmd_mirror_catalog $@
        exit 0
    ;;
    download-db)
        echo "Downloading database..."
        shift
        cmd_download_db $@
        exit 0
    ;;
    mirror-operator)
        echo "Mirroring operator..."
        shift
        cmd_mirror_operator $@
        exit 0
    ;;
    *)
        cmd_usage ${0}
        exit 1
    ;;
esac
