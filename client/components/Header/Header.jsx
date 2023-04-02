import { Flex, Text } from '@chakra-ui/react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';

const Header = () => {
    return (
        <Flex justifyContent="space-between" alignItems="center" height="10vh" width="100%" p="2rem">
           <img src="Logo.png" alt="logo" style={{ width: '200px', height: 'auto' }} />
            <Flex width="30%" justifyContent="space-between" alignItems="center">
                <Text><Link href="/">Home</Link></Text>
                <Text><Link href="/xxxxx">xxxx</Link></Text>
                <Text><Link href="/xxxxx">yyyyyy</Link></Text>
            </Flex>
            <ConnectButton />
        </Flex>
    )   
}

export default Header;