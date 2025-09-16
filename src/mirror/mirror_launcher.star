shared_utils = import_module("../shared_utils/shared_utils.star")
static_files = import_module("../static_files/static_files.star")
constants = import_module("../package_io/constants.star")
input_parser = import_module("../package_io/input_parser.star")
SERVICE_NAME = "mirror"
HTTP_PORT_ID = "http"
HTTP_PORT_NUMBER = 5050

# MIN_CPU = 100
# MAX_CPU = 300
# MIN_MEMORY = 128
# MAX_MEMORY = 256

USED_PORTS = {
    HTTP_PORT_ID: shared_utils.new_port_spec(
        HTTP_PORT_NUMBER,
        shared_utils.TCP_PROTOCOL,
        shared_utils.HTTP_APPLICATION_PROTOCOL,
    )
}


def launch_mirror(
    plan,
    participants,
    cl_contexts,
    mirror_port,
    mirror_params,
    port_publisher,
    index,
    # global_node_selectors,
    global_tolerations,
    docker_cache_params,
):
    tolerations = shared_utils.get_tolerations(global_tolerations=global_tolerations)

    public_ports = shared_utils.get_additional_service_standard_public_port(
        port_publisher,
        constants.HTTP_PORT_ID,
        index,
        0,
    )

    all_cl_client_info = []
    for index, participant in enumerate(participants):
        el_type = participant.el_type
        cl_type = participant.cl_type
        index_str = shared_utils.zfill_custom(
            index + 1, len(str(len(participants)))
        )
        pair_name = "{0}-{1}-{2}".format(index_str, cl_type, el_type)
        all_cl_client_info.append(
            new_cl_client_info(
                cl_contexts[index].beacon_http_url,
                pair_name,
            )
        )

    if mirror_port != None:
        public_ports = {
            HTTP_PORT_ID: shared_utils.new_port_spec(
                mirror_port, shared_utils.TCP_PROTOCOL
            )
        }

    config = get_config(
        mirror_params,
        public_ports,
        all_cl_client_info,
        # global_node_selectors,
        tolerations,
        docker_cache_params,
    )

    mirror_service = plan.add_service(SERVICE_NAME, config)
    return mirror_service.ip_address


def get_config(
    mirror_params,
    public_ports,
    all_cl_client_info,
    # node_selectors,
    tolerations,
    docker_cache_params,
):
    cmd = [
        "-primary=\"{}|{}\"".format(all_cl_client_info[0]["FullName"], all_cl_client_info[0]["Beacon_HTTP_URL"]),
        "-mirrors=\"{}\"".format(",".join(["{}|{}".format(client["FullName"], client["Beacon_HTTP_URL"]) for client in all_cl_client_info[1:]])),
    ]

    return ServiceConfig(
        image=mirror_params.image,
        ports=USED_PORTS,
        public_ports=public_ports,
        cmd=cmd,
        # node_selectors=node_selectors,
        tolerations=tolerations,
    )

def new_cl_client_info(beacon_http_url, full_name):
    return {
        "Beacon_HTTP_URL": beacon_http_url,
        "FullName": full_name,
    }
