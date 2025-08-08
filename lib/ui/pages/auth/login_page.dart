import 'package:event_management/core/constants/build_text.dart';
import 'package:event_management/ui/pages/auth/sign_up_page.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:event_management/ui/widgets/custom_input.dart';
import 'package:event_management/ui/widgets/custom_password.dart';
import 'package:event_management/ui/widgets/default_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/login_provider.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<LoginProvider>(context);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  BuildText(
                    textAlign: TextAlign.center,
                    text: "Manage Event",
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  AppDimensions.h16,
                  BuildText(
                    textAlign: TextAlign.center,
                    text: "Login with your email and password.",
                    fontSize: 14,
                  ),
                  AppDimensions.h24,
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: provider.formKey,
                      child: Column(
                        children: [
                          CustomInput(
                            controller: provider.emailController,

                            fieldLabel: "Email",

                            hintText: "Enter your mail",
                            validation: true,
                            validatorClass: (value) {
                              final regex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              );

                              if (value == null || value.isEmpty) {
                                return "Email is required";
                              } else if (!regex.hasMatch(value)) {
                                return "Enter a valid email";
                              }

                              return null;
                            },
                            errorMessage: "Email is wrong",
                          ),

                          AppDimensions.h16,

                          CustomPassword(
                            controller: provider.passwordController,
                            fieldLabel: "Password",
                            hintText: "Enter your password",
                            errorMessage: "Password is wrong",
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppDimensions.h24,

                  DefaultButton(
                    isLoading: provider.isLoading,
                    text: "Login",
                    press: () {
                      if (provider.formKey.currentState!.validate()) {
                        provider.login(context);
                      }
                    },
                  ),

                  AppDimensions.h24,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BuildText(text: "Don't have an Account? ", fontSize: 14),

                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        ),
                        child: BuildText(
                          color: colorScheme.primary,
                          text: "Sign Up",
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
