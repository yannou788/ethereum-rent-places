const Migrations = artifacts.require("Migrations");
const PlaceRent = artifacts.require("PlaceRent");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(PlaceRent);
};
