{
  description = "elixir and kafka demo";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";

  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.process-compose-flake.flakeModule
      ];
      perSystem = { self', pkgs, lib, ... }: {
        process-compose."default" = { config, ... }:
          let
            appName = "kbway";
          in
          {
            imports = [
              inputs.services-flake.processComposeModules.default
            ];

            services.zookeeper."z1".enable = true;
            services.zookeeper."z1".port = 2182;
            services.apache-kafka."k1" = {
              enable = true;
              port = 9094;
              settings = {
                "offsets.topic.replication.factor" = 1;
                "zookeeper.connect" = [ "localhost:2182" ];
              };
            };
            # kafka should start only after zookeeper is healthy
            settings.processes.k1.depends_on."z1".condition = "process_healthy";
            settings.processes.test =
              {
                command = pkgs.writeShellApplication {
                  runtimeInputs = [ pkgs.bash config.services.apache-kafka.k1.package ];
                  text = ''
                    # Create a topic
                    kafka-topics.sh --create --bootstrap-server localhost:9094 --partitions 3 \
                    --replication-factor 1 --topic test

                    # Producer
                    echo 'test 1' | kafka-console-producer.sh --broker-list localhost:9094 --topic testtopic

                    # Consumer
                    kafka-console-consumer.sh --bootstrap-server localhost:9094 --topic testtopic \
                    --from-beginning --max-messages 1 | grep -q "test 1"
                  '';
                  name = "kafka-test";
                };
                depends_on."k1".condition = "process_healthy";
              };

          };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ beam.packages.erlang_27.elixir_1_17 mix2nix ];
        };
      };
    };
}
