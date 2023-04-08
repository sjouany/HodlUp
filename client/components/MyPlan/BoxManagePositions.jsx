import { Box, Center, Flex, Icon, Select, VStack, Checkbox, Text, HStack, Image } from "@chakra-ui/react";
import { FaExchangeAlt } from "react-icons/fa";
import { useAccount, useProvider, useSigner } from 'wagmi'
import { getNetwork } from '@wagmi/core'
import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import hodlUpHubfromContract from "../../src/contracts/HodlUpHub.json"
import ERC20Contract from "../../src/contracts/ERC20.json"

function BoxManagePositions(props) {
  const [myContract, setMyContract] = useState(null);
  const [myAddress, setMyAddress] = useState("0x");
  const { data: signer } = useSigner();
  const provider = useProvider();

  const loadContract = async () => {

    const { chain } = getNetwork();
    //const contractAddress = hodlUpHubfromContract.networks[137].address;
    const hodlUpContractAddress = hodlUpHubfromContract.networks[chain.id == 1337 ? 137 : chain.id].address;
    const hodlUpContractABI = hodlUpHubfromContract.abi;
    const hodlUpContract = new ethers.Contract(hodlUpContractAddress, hodlUpContractABI, signer);
    //console.log(signer);
    // Stockez le contrat dans l'état du composant --chain.chainId=
    setMyContract(hodlUpContract);
   // setMyAddress(address);
  };

  useEffect(() => {
    loadContract();
  }, [useProvider, signer, useAccount]);

  // const events = useContractEvent(contract, "Transfer", {
  //   fromBlock: 0,
  //   toBlock: "latest"
  // });

  return (

    <Box className="box_create_position" p="5" borderWidth="1px" position="relative">
    <Flex align="baseline" mt={2}>
        <VStack spacing="4" p="4">
        </VStack>
    </Flex>
    </Box>
  );
}

export default BoxManagePositions;