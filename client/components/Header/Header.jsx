import { Flex, Text } from '@chakra-ui/react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';

const Header = () => {
    return (
      <Flex
        justifyContent="space-between"
        alignItems="center"
        height="10vh"
        width="100%"
        p="2rem"
        borderBottom="1px solid white" // Ajout de la bordure en bas
      >
        <img src="Logo.png" alt="logo" style={{ width: '200px', height: 'auto' }} />
        <Flex width="30%" justifyContent="space-between" alignItems="center" color="white">
          <Text><Link href="/">Home</Link></Text>
          <Text><Link href="/">What is DCA ?</Link></Text>
          <Text><Link href="/">Contact</Link></Text>
        </Flex>
        <ConnectButton />
      </Flex>
    );
  };
  
  export default Header;
  