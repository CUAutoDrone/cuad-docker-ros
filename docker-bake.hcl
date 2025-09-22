target "default" {
    description = "The main target to build for all architectures"
    tags = ["ghcr.io/cuautodrone/cuad-ros:test"]
    args = {
        "ROS_APT_SOURCE_VERSION" = null
    }
    cache-from = [ "type=gha" ]
    cache-to = [ "type=gha,mode=max" ]
    attest = [
        {
            type="provenance"
            mode="max"
        },
        {
            type="sbom"
        }
    ]
    platforms=["linux/amd64", "linux/arm/v5", "linux/arm64/v8"]
}

target "validate-build" {
    inherits = ["default"]
    call = "check"
}