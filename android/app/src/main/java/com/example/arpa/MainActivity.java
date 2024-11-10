package com.example.arpa;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

import androidx.annotation.NonNull;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.Scanner;
import java.util.concurrent.TimeUnit;

public class MainActivity extends FlutterActivity {

	private static final String CHANNEL = "warp.native";
	private static final int WORKSN = 16;

	private void pingRoutine(String ipv4, MethodChannel dch){
		System.out.println("start pinging...");
		try {
			Scanner ipv4Addr = new Scanner(ipv4);
			ipv4Addr.useDelimiter("\\.");
			String netAddr = String.format("%d.%d.%d",
					ipv4Addr.nextInt(),
					ipv4Addr.nextInt(),
					ipv4Addr.nextInt()
			);

			//List<String> listr = new LinkedList<>();
			for (int hostAddrPart = 0; hostAddrPart < 255 / WORKSN; hostAddrPart++){
				Process[] ps = new Process[WORKSN];
				for(int i = 0; i < WORKSN; i++){
					int hostAddr = (hostAddrPart * WORKSN) + i;
					ps[i] = Runtime.getRuntime()
							.exec(String.format("ping -w 1 -c 1 %s",
									String.format("%s.%d", netAddr, hostAddr)));
				}
				Thread.sleep(200);
				for(int i = 0; i < WORKSN; i++) {
					int hostAddr = (hostAddrPart * WORKSN) + i;
					Process p = ps[i];
					if(!p.waitFor(25, TimeUnit.MILLISECONDS)){
						// it seems that we cant really reach that
						System.out.println(String.format("giveup on %d", hostAddr));
						p.destroy();
						//esink.success(String.format("{\"ipv4\":\"%s\"}, \"find\":0", hostAddr));
						//listr.add(String.format("%d 0", hostAddr));
						//ech.
					} else {
						dch.invokeMethod("", String.format("%d", hostAddr));
						//BufferedReader ostream = new BufferedReader(new InputStreamReader(p.getInputStream()));
						//BufferedReader estream = new BufferedReader(new InputStreamReader(p.getErrorStream()));
						//BufferedReader iReader =
						//		new BufferedReader(new InputStreamReader(p.getErrorStream()));
						//BufferedReader eReader =
						//		new BufferedReader(new InputStreamReader(p.getInputStream()));
						//String line;
						//String ret = "";
						//while ((line = iReader.readLine()) != null) {
						//	ret += line + '\n';
						//}
						//System.out.print(ret);
						//ret = "";
						//while ((line = eReader.readLine()) != null) {
						//	ret += line + '\n';
						//}
						//System.out.print(ret);
						//esink.success(String.format("{\"ipv4\":\"%s\"}", hostAddr));
						//listr.add(String.format("%d 1", hostAddr));
					}
				}
			}
			//result.success(listr);
		} catch(Exception e){
			e.printStackTrace();
		}
	}

	private void ping(String ipv4, MethodChannel.Result result){
		System.out.println(String.format("ping %s", ipv4));
		try {
			// prevent too fast
			Process ps = Runtime.getRuntime()
					.exec(String.format("ping -w 1 -c 1 %s", ipv4));
			if(!ps.waitFor(1000, TimeUnit.MILLISECONDS)){
				System.out.println(String.format("giveup on %s", ipv4));
				ps.destroy();
				result.success("{\"exist\":\"false\"}");
			} else {
				try {
					if(ps.exitValue() != 0) {
						result.success("{\"exist\":\"false\"}");
					}
					BufferedReader bf = new BufferedReader(new InputStreamReader(ps.getInputStream()));
					bf.readLine();
					String ln = bf.readLine();
					String[] tkn = ln.split("\\s+");
					String ttl = tkn[5].split("\\=+")[1];
					String delay = tkn[6].split("\\=+")[1];
					System.out.println(String.format("GOT TTL: %s DELAY: %s", ttl, delay));
					result.success(
							String.format(
									"{\"exist\":\"true\", \"ttl\":\"%s\", \"delay\":\"%s\"}",
									ttl,
									delay
							)
					);
				} catch(Exception e){
					result.success("{\"exist\":\"true\"}");
				}
			}
		} catch(Exception e){
			e.printStackTrace();
		}
	}

	@Override
	public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
		super.configureFlutterEngine(flutterEngine);
		new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
			.setMethodCallHandler(
			(call, result) -> {
				if (call.method.equals("scan")) {
					try {
						new Thread(new Runnable() {
							@Override
							public void run() {
								try {
									String ipv4 = call.argument("ipv4");
									ping(ipv4, result);

									//MethodChannel dchannel = new MethodChannel(
									//		flutterEngine.getDartExecutor().getBinaryMessenger(),
									//		String.format("warp.discover/%s", ipv4)
									//);
									//pingRoutine(ipv4, dchannel);

								} catch (Exception e) {
									e.printStackTrace();
								}
							}
						}).start();
					} catch(Exception e) {
						e.printStackTrace();
					}

				} else {
					result.notImplemented();
				}
			}
		);

	}

}
